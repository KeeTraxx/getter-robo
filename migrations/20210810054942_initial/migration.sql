-- CreateTable
CREATE TABLE "Anime" (
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "newestEpisode" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "name" TEXT NOT NULL PRIMARY KEY,
    "mainImageId" INTEGER,
    FOREIGN KEY ("mainImageId") REFERENCES "AnimeImage" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "AnimeImage" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "animeName" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("animeName") REFERENCES "Anime" ("name") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "AnimeSubber" (
    "animeName" TEXT NOT NULL,
    "subberName" TEXT NOT NULL,
    "autodownload" BOOLEAN NOT NULL DEFAULT false,

    PRIMARY KEY ("animeName", "subberName"),
    FOREIGN KEY ("animeName") REFERENCES "Anime" ("name") ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY ("subberName") REFERENCES "Subber" ("name") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Episode" (
    "animeName" TEXT NOT NULL,
    "episode" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY ("animeName", "episode"),
    FOREIGN KEY ("animeName") REFERENCES "Anime" ("name") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Subber" (
    "name" TEXT NOT NULL PRIMARY KEY,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "Torrent" (
    "infoHash" TEXT NOT NULL PRIMARY KEY,
    "title" TEXT NOT NULL,
    "link" TEXT NOT NULL,
    "pubDate" DATETIME NOT NULL,
    "guid" TEXT NOT NULL,
    "resolution" INTEGER NOT NULL,
    "extention" TEXT NOT NULL,
    "subberName" TEXT NOT NULL,
    "animeName" TEXT NOT NULL,
    "episodeString" TEXT NOT NULL,
    FOREIGN KEY ("animeName") REFERENCES "Anime" ("name") ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY ("animeName", "episodeString") REFERENCES "Episode" ("animeName", "episode") ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY ("subberName") REFERENCES "Subber" ("name") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateIndex
CREATE UNIQUE INDEX "AnimeImage.animeName_url_unique" ON "AnimeImage"("animeName", "url");

-- CreateIndex
CREATE UNIQUE INDEX "Torrent.link_unique" ON "Torrent"("link");

-- CreateIndex
CREATE UNIQUE INDEX "Torrent.guid_unique" ON "Torrent"("guid");
