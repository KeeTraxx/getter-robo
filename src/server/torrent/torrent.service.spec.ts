import { Test, TestingModule } from '@nestjs/testing';
import { TorrentService } from './torrent.service';

describe('TorrentService', () => {
  let service: TorrentService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [TorrentService],
    }).compile();

    service = module.get<TorrentService>(TorrentService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
