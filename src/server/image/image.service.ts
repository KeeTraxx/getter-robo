import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { Anime } from '@prisma/client';
import { customsearch_v1 } from 'googleapis';
import { NyaaService } from '../nyaa/nyaa.service';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ImageService implements OnModuleInit {
  private readonly logger = new Logger(ImageService.name);
  private readonly CX = process.env.GOOGLE_CSE_CX;
  private readonly API_KEY = process.env.GOOGLE_API_KEY;

  constructor(
    private prismaService: PrismaService,
    private nyaaService: NyaaService,
  ) {}

  async onModuleInit() {
    this.logger.log(this.CX, this.API_KEY);
    // this.saveImages(await this.prismaService.anime.findFirst());
    this.nyaaService.newAnime$.subscribe(
      async (anime) => await this.saveImages(anime),
    );
  }

  async saveImages(anime: Anime): Promise<Anime> {
    if (!this.CX || !this.API_KEY) {
      return;
    }
    this.logger.log(`Loading images for ${anime.name}...`);
    const c = new customsearch_v1.Customsearch({ auth: this.API_KEY });
    const results = await c.cse.list({
      cx: this.CX,
      q: anime.name,
      searchType: 'image',
      imgSize: 'large',
    });

    if (results) {
      for (const img of results.data?.items) {
        /*
                {
          kind: 'customsearch#result',
          title: 'Neon Genesis Evangelion: The 10 Best Anime Fight Scenes - Somag News',
          htmlTitle: 'Neon Genesis <b>Evangelion</b>: The 10 Best Anime Fight Scenes - Somag News',
          link: 'https://www.somagnews.com/wp-content/uploads/2021/05/Neon-Genesis-Evangelion.jpg',
          displayLink: 'www.somagnews.com',
          snippet: 'Neon Genesis Evangelion: The 10 Best Anime Fight Scenes - Somag News',
          htmlSnippet: 'Neon Genesis <b>Evangelion</b>: The 10 Best Anime Fight Scenes - Somag News',
          mime: 'image/jpeg',
          fileFormat: 'image/jpeg',
          image: {
            contextLink: 'https://www.somagnews.com/neon-genesis-evangelion-the-10-best-anime-fight-scenes/',
            height: 264,
            width: 704,
            byteSize: 61913,
            thumbnailLink: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSMQVcl2x6bDtMkRHKpjSN86KeFgmIJWqD0RXC2ibTYewpx1OkT8hZq7A&s',
            thumbnailHeight: 53,
            thumbnailWidth: 140
          }
        }*/
        /*this.prismaService.animeImage.upsert({
          create: {
            url: img.link,
            animeName: anime.name,
          },
          update: {},
          where: {
            animeName_url: {
              animeName: anime.name,
              url: img.link,
            },
          },
        });*/

        const a = await this.prismaService.anime.update({
          data: {
            images: {
              upsert: {
                create: {
                  url: img.link,
                },
                update: {},
                where: {
                  animeName_url: { animeName: anime.name, url: img.link },
                },
              },
            },
          },
          where: { name: anime.name },
        });
        if (!a.mainImageId) {
          this.logger.log(`Setting main image for ${a.name}...`);
          const img = await this.prismaService.animeImage.findFirst({
            where: { animeName: a.name },
          });
          await this.prismaService.anime.update({
            data: { mainImageId: img.id },
            where: { name: a.name },
          });
        }
      }
    }

    return this.prismaService.anime.findUnique({ where: { name: anime.name } });
  }
}
