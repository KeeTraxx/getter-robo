import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { Anime, Torrent } from '@prisma/client';
import moment from 'moment';
import * as Parser from 'rss-parser';
import { Subject } from 'rxjs';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class NyaaService implements OnModuleInit {
  private readonly logger = new Logger(NyaaService.name);
  private readonly rssParser = new Parser({
    customFields: {
      item: [
        ['nyaa:infoHash', 'infoHash'],
        ['nyaa:size', 'size'],
        ['nyaa:trusted', 'trusted'],
        ['nyaa:remake', 'remake'],
      ],
    },
  });
  private readonly regex =
    /^\[(.+?)\]\s+([^\[\]]+?)\s*-\s+(\d+)\s+.*(720|1080|480).*\.(mp4|mkv)$/;

  public readonly savedTorrents$ = new Subject<Torrent>();
  public readonly newAnime$ = new Subject<Anime>();

  constructor(private prismaService: PrismaService) {}

  onModuleInit() {
    this.queryNyaa();
  }

  @Cron(CronExpression.EVERY_30_MINUTES)
  async cron() {
    this.queryNyaa();
  }

  async queryNyaa(query = '') {
    const url = this.buildUrl([query, '720'].filter(Boolean).join(' '));
    this.logger.log(`FETCHING URL ${url}`);
    const feed = await this.rssParser.parseURL(url);
    for (const item of feed.items.sort((a, b) =>
      a.isoDate.localeCompare(b.isoDate),
    )) {
      await this.rssItemToTorrent(item);
    }
  }

  async rssItemToTorrent(rssItem: any): Promise<Torrent> {
    const regexResult = this.regex.exec(rssItem.title);

    if (regexResult) {
      const [, subberName, animeName, episodeString, resolution, extention] =
        regexResult;
      const { infoHash, guid, title, link, pubDate } = rssItem;
      try {
        if (
          (await this.prismaService.torrent.count({ where: { infoHash } })) > 0
        )
          return;

        this.logger.log(`Saving ${title}`);

        if (
          (await this.prismaService.anime.count({
            where: { name: animeName },
          })) == 0
        ) {
          const anime = await this.prismaService.anime.upsert({
            create: {
              name: animeName,
            },
            update: {},
            where: { name: animeName },
          });
          this.newAnime$.next(anime);
        }

        await this.prismaService.subber.upsert({
          create: {
            name: subberName,
          },
          update: {},
          where: {
            name: subberName,
          },
        });

        await this.prismaService.animeSubber.upsert({
          create: { animeName, subberName },
          update: {},
          where: { animeName_subberName: { animeName, subberName } },
        });

        const episode = await this.prismaService.episode.upsert({
          create: {
            animeName: animeName,
            episode: episodeString,
            createdAt: new Date(pubDate),
          },
          update: {},
          where: {
            animeName_episode: {
              animeName,
              episode: episodeString,
            },
          },
        });

        const anime = await this.prismaService.anime.findUnique({
          where: { name: animeName },
        });

        if (moment(episode.createdAt).isAfter(anime.newestEpisode)) {
          await this.prismaService.anime.update({
            data: { newestEpisode: new Date(episode.createdAt) },
            where: { name: animeName },
          });
        }

        const torrent = await this.prismaService.torrent.upsert({
          create: {
            extention,
            guid,
            infoHash,
            link,
            pubDate: new Date(pubDate),
            resolution: parseInt(resolution),
            title,
            animeName,
            episodeString,
            subberName,
          },
          update: {},
          where: { infoHash },
        });

        this.savedTorrents$.next(torrent);
        return torrent;
      } catch (err) {
        this.logger.error(err);
      }
    } else {
      this.logger.warn(`${rssItem.title} not parseable!`);
    }
  }

  private buildUrl(...query: string[]) {
    return `https://nyaa.si/?page=rss&q=${query.join(' ')}&c=1_2&m=1&f=0`;
  }
}
