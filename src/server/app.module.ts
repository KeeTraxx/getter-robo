import { Module } from '@nestjs/common';
import { PrismaService } from './prisma/prisma.service';
import { AnimeController } from './anime/anime.controller';
import { NyaaService } from './nyaa/nyaa.service';
import { ScheduleModule } from '@nestjs/schedule';
import { AutoDownloadService } from './auto-download/auto-download.service';
import { ImageService } from './image/image.service';
import { HttpModule } from '@nestjs/axios';
import { TorrentService } from './torrent/torrent.service';

@Module({
  imports: [ScheduleModule.forRoot(), HttpModule],
  controllers: [AnimeController],
  providers: [
    PrismaService,
    NyaaService,
    AutoDownloadService,
    ImageService,
    TorrentService,
  ],
})
export class AppModule {}
