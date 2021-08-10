import { HttpService } from '@nestjs/axios';
import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { firstValueFrom, Subscription } from 'rxjs';
import { NyaaService } from '../nyaa/nyaa.service';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AutoDownloadService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(NyaaService.name);
  private readonly AUTODOWNLOAD_TARGET = process.env.AUTODOWNLOAD_TARGET;
  private savedTorrentsSubscription: Subscription;

  constructor(
    private nyaaService: NyaaService,
    private prismaService: PrismaService,
    private httpService: HttpService,
  ) {}

  onModuleInit() {
    this.logger.log(`AUTODOWNLOAD_TARGET: ${this.AUTODOWNLOAD_TARGET}`);
    this.savedTorrentsSubscription = this.nyaaService.savedTorrents$.subscribe(
      async ({ animeName, resolution, subberName, link, episodeString }) => {
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
          this.logger.log(
            `Downloading magnetLink ${animeName} ${episodeString}...`,
          );
          try {
            await firstValueFrom(
              this.httpService.post(this.AUTODOWNLOAD_TARGET, {
                magnetURI: link,
              }),
            );
          } catch (err) {
            this.logger.error(err);
          }
        }
      },
    );
  }
  onModuleDestroy() {
    this.savedTorrentsSubscription.unsubscribe();
  }
}
