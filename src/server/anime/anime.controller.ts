import { Body, Controller, Get, Logger, Post, Put } from '@nestjs/common';
import { Anime, AnimeSubber, Torrent } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import * as moment from 'moment';
import { TorrentService } from '../torrent/torrent.service';
import { NyaaService } from '../nyaa/nyaa.service';

@Controller(['api/anime'])
export class AnimeController {
  private readonly logger = new Logger(AnimeController.name);
  constructor(
    private readonly prismaService: PrismaService,
    private readonly torrentService: TorrentService,
    private readonly nyaaService: NyaaService,
  ) {}

  @Get()
  async index(): Promise<Array<Anime>> {
    return (
      await this.prismaService.anime.findMany({
        orderBy: [{ newestEpisode: 'desc' }],
        take: 50,
        include: {
          subbers: {},
          episodes: {
            orderBy: { episode: 'desc' },
            include: { torrents: { orderBy: { subberName: 'asc' } } },
          },
          mainImage: {},
          images: {},
        },
      })
    ).map((a) => ({
      ...a,
      age: moment(a.newestEpisode).fromNow(),
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

  @Post('download')
  async download(@Body() { infoHash }: { infoHash: string }): Promise<Torrent> {
    const torrent = await this.prismaService.torrent.findUnique({
      where: { infoHash },
    });
    this.logger.log(`Downloading infohash ${torrent.title}`);
    this.torrentService.downloadTorrent(torrent);
    return torrent;
  }

  @Post('more')
  async more(@Body() { query }: { query: string }): Promise<void> {
    await this.nyaaService.queryNyaa(query);
  }

  @Post('image')
  async setImage(
    @Body() { animeName, id }: { animeName: string; id: number },
  ): Promise<void> {
    await this.prismaService.anime.update({
      data: {
        mainImageId: id,
      },
      where: {
        name: animeName,
      },
    });
  }
}
