import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { NyaaService } from '../nyaa/nyaa.service';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AutoDownloadService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(NyaaService.name);

  constructor(
    private nyaaService: NyaaService,
    private prismaService: PrismaService,
  ) {}

  onModuleInit() {
    this.nyaaService.savedTorrents$.subscribe(
      async ({ animeName, resolution, subberName, link }) => {
        if (
          resolution == 720 &&
          (await this.prismaService.animeSubbers.count({
            where: {
              animeName,
              subberName,
              autodownload: true,
            },
          })) > 0
        ) {
          this.logger.log(`Downloading magnetLink ${link}...`);
        }
      },
    );
  }
  onModuleDestroy() {}
}
