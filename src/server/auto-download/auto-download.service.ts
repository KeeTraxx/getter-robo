import { HttpService } from '@nestjs/axios';
import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { Subscription } from 'rxjs';
import { NyaaService } from '../nyaa/nyaa.service';
import { PrismaService } from '../prisma/prisma.service';
import { TorrentService } from '../torrent/torrent.service';

@Injectable()
export class AutoDownloadService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(AutoDownloadService.name);
  private savedTorrentsSubscription: Subscription;

  constructor(
    private nyaaService: NyaaService,
    private prismaService: PrismaService,
    private httpService: HttpService,
    private torrentService: TorrentService,
  ) {}

  onModuleInit() {
    this.savedTorrentsSubscription = this.nyaaService.savedTorrents$.subscribe(
      async (torrent) => {
        const { animeName, resolution, subberName } = torrent;
        if (
          resolution == 720 &&
          (await this.prismaService.animeSubber.count({
            where: {
              animeName,
              subberName,
              autodownload: true,
            },
          })) > 0
        ) {
          this.torrentService.downloadTorrent(torrent);
        }
      },
    );
  }
  onModuleDestroy() {
    this.savedTorrentsSubscription.unsubscribe();
  }
}
