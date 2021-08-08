import { Body, Controller, Get, Put } from '@nestjs/common';
import { ApiBody } from '@nestjs/swagger';
import { Anime, AnimeSubbers } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Controller(['api/anime'])
export class AnimeController {
  constructor(private readonly prismaService: PrismaService) {}

  @Get()
  async index(): Promise<Array<Anime>> {
    return this.prismaService.anime.findMany({
      orderBy: [{ newestEpisode: 'desc' }],
      take: 50,
      include: { AnimeSubbers: {}, Episode: { orderBy: { episode: 'desc' } } },
    });
  }

  @Put()
  async setAutoDownload(@Body() newSub: AnimeSubbers): Promise<AnimeSubbers> {
    const a = await this.prismaService.animeSubbers.update({
      data: newSub,
      where: {
        animeName_subberName: {
          animeName: newSub.animeName,
          subberName: newSub.subberName,
        },
      },
    });
    return a;
  }
}
