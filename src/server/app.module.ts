import { Module } from '@nestjs/common';
import { PrismaService } from './prisma/prisma.service';
import { AnimeController } from './anime/anime.controller';
import { NyaaService } from './nyaa/nyaa.service';
import { ScheduleModule } from '@nestjs/schedule';

@Module({
  imports: [ScheduleModule.forRoot()],
  controllers: [AnimeController],
  providers: [PrismaService, NyaaService],
})
export class AppModule {}
