import { Controller, Get } from '@nestjs/common';
import { Anime } from '@prisma/client';

@Controller('torrent')
export class TorrentController {
  async get(): Promise<Array<Anime>> {
    return [];
  }
}
