import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { Torrent } from '@prisma/client';
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

  constructor(private prismaService: PrismaService) {}

  onModuleInit() {
    this.parseRss();
  }

  @Cron(CronExpression.EVERY_30_MINUTES)
  async parseRss() {
    const url = this.buildUrl('720');
    this.logger.log(`FETCHING URL ${url}`);
    const feed = await this.rssParser.parseURL(url);
    for (let item of feed.items.sort((a, b) =>
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
      const { infoHash, size, trusted, remake, guid, title, link, pubDate } =
        rssItem;
      try {
        if (
          (await this.prismaService.torrent.count({ where: { infoHash } })) > 0
        )
          return;

        this.logger.log(`Saving ${title}`);

        const anime = await this.prismaService.anime.upsert({
          create: {
            name: animeName,
          },
          update: {},
          where: { name: animeName },
        });

        const subber = await this.prismaService.subber.upsert({
          create: {
            name: subberName,
          },
          update: {},
          where: {
            name: subberName,
          },
        });

        const animeSubber = await this.prismaService.animeSubbers.upsert({
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

        this.prismaService.anime.update({
          data: { newestEpisode: new Date(episode.createdAt) },
          where: { name: animeName },
        });

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
