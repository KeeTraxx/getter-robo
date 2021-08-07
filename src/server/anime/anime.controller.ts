import { Controller, Get } from '@nestjs/common';
import { Anime } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Controller(['api/anime'])
export class AnimeController {
  constructor(private readonly prismaService: PrismaService) {}

  @Get()
  async index(): Promise<Array<Anime>> {
    return this.prismaService.anime.findMany();
  }
}
