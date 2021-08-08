import { Test, TestingModule } from '@nestjs/testing';
import { AutoDownloadService } from './auto-download.service';

describe('AutoDownloadService', () => {
  let service: AutoDownloadService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [AutoDownloadService],
    }).compile();

    service = module.get<AutoDownloadService>(AutoDownloadService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
