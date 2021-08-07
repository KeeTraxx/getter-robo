import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { Torrent } from '@prisma/client';
import * as Parser from 'rss-parser';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class NyaaService implements OnModuleInit {
  private readonly logger = new Logger(NyaaService.name);
  private readonly rssParser = new Parser();
  private readonly regex =
    /^\[(.+?)\]\s+([^\[\]]+?)\s*-\s+(\d+)\s+.*(720|1080|480).*\.(mp4|mkv)$/;

  constructor(private prismaService: PrismaService) {}

  onModuleInit() {
    this.parseRss();
  }

  @Cron(CronExpression.EVERY_30_MINUTES)
  async parseRss() {
    const url = this.buildUrl('720');
    this.logger.log(`FETCHING URL ${url}`);
    const feed = await this.rssParser.parseURL(url);
    const torrents = feed.items.map(this.rssItemToTorrent);
  }

  rssItemToTorrent(rssItem: Parser.Item): Torrent {
    console.log(rssItem);
    const [, subber, name, episode, resolution, extention] = this.regex.exec(
      rssItem.title,
    );
    this.prismaService.anime.upsert({
      create: {
        name,
      },
      update: {},
      where: { name },
    });
    return null;
  }

  private buildUrl(...query: string[]) {
    return `https://nyaa.si/?page=rss&q=${query.join(' ')}&c=1_2&m=1&f=0`;
  }
}
