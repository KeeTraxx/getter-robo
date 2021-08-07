import { Test, TestingModule } from '@nestjs/testing';
import { NyaaService } from './nyaa.service';

describe('NyaaService', () => {
  let service: NyaaService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [NyaaService],
    }).compile();

    service = module.get<NyaaService>(NyaaService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
