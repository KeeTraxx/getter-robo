import { Body, Controller, Get, Put } from '@nestjs/common';
import { Anime, AnimeSubber } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import * as moment from 'moment';

@Controller(['api/anime'])
export class AnimeController {
  constructor(private readonly prismaService: PrismaService) {}

  @Get()
  async index(): Promise<Array<Anime>> {
    return (
      await this.prismaService.anime.findMany({
        orderBy: [{ newestEpisode: 'desc' }],
        take: 50,
        include: {
          subbers: {},
          episodes: { orderBy: { episode: 'desc' } },
          mainImage: {},
        },
      })
    ).map((a) => ({
      ...a,
      age: moment(a.createdAt).fromNow(),
    }));
  }

  @Put()
  async setAutoDownload(@Body() newSub: AnimeSubber): Promise<AnimeSubber> {
    const a = await this.prismaService.animeSubber.update({
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
