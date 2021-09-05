import { HttpService } from '@nestjs/axios';
import { Injectable, Logger } from '@nestjs/common';
import { Torrent } from '@prisma/client';
import { firstValueFrom } from 'rxjs';
import { PrismaService } from '../prisma/prisma.service';
import ADAPTIVE_CARD_TEMPLATE from './template.json';
@Injectable()
export class TorrentService {
  private readonly logger = new Logger(TorrentService.name);

  private readonly AUTODOWNLOAD_TARGET = process.env.AUTODOWNLOAD_TARGET;
  private readonly DISCORD_WEBHOOK_URL = process.env.DISCORD_WEBHOOK_URL;

  constructor(
    private httpService: HttpService,
    private readonly prismaService: PrismaService,
  ) {
    this.logger.log(`AUTODOWNLOAD_TARGET: ${this.AUTODOWNLOAD_TARGET}`);
  }
  async downloadTorrent(torrent: Torrent): Promise<Torrent> {
    const { link } = torrent;
    this.logger.log(`Downloading magnetLink ${link}...`);
    try {
      if (this.AUTODOWNLOAD_TARGET) {
        await firstValueFrom(
          this.httpService.post(this.AUTODOWNLOAD_TARGET, {
            magnetURI: link,
          }),
        );
      }

      await this.prismaService.torrent.update({
        where: { link },
        data: { downloadAt: new Date() },
      });

      if (this.DISCORD_WEBHOOK_URL) {
        const torrent = this.prismaService.torrent.findUnique({
          where: { link },
        });
        const anime = await torrent.anime();
        const episode = await torrent.episode();
        const mainImage = await torrent.anime().mainImage();
        const subber = await torrent.subber();

        const embeds = [];

        if (mainImage) {
          embeds.push({
            image: {
              url: mainImage.url,
            },
          });
        }

        embeds.push({
          title: `${anime.name} ${episode.episode} (${subber.name}) downloaded.`,
        });

        embeds.push({
          fields: [
            {
              name: 'Anime',
              value: anime.name,
            },
            {
              name: 'Episode',
              value: episode.episode,
            },
            {
              name: 'Subber',
              value: subber.name,
            },
          ],
        });

        this.logger.log(`sending CARD to ${this.DISCORD_WEBHOOK_URL}`);

        await firstValueFrom(
          this.httpService.post(this.DISCORD_WEBHOOK_URL, {
            embeds,
          }),
        );
      }
    } catch (err) {
      this.logger.error(`${err}: ${err?.response?.data}`);
    }
    return;
  }
}
