import { HttpService } from '@nestjs/axios';
import { Injectable, Logger } from '@nestjs/common';
import { Torrent } from '@prisma/client';
import { firstValueFrom } from 'rxjs';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class TorrentService {
  private readonly logger = new Logger(TorrentService.name);

  private readonly AUTODOWNLOAD_TARGET = process.env.AUTODOWNLOAD_TARGET;

  constructor(
    private httpService: HttpService,
    private readonly prismaService: PrismaService,
  ) {
    this.logger.log(`AUTODOWNLOAD_TARGET: ${this.AUTODOWNLOAD_TARGET}`);
  }
  async downloadTorrent({ link }: Torrent): Promise<Torrent> {
    this.logger.log(`Downloading magnetLink ${link}...`);
    try {
      await firstValueFrom(
        this.httpService.post(this.AUTODOWNLOAD_TARGET, {
          magnetURI: link,
        }),
      );
      await this.prismaService.torrent.update({
        where: { link },
        data: { downloadAt: new Date() },
      });
    } catch (err) {
      this.logger.error(err);
    }
    return;
  }
}
