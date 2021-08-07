/*
  Warnings:

  - A unique constraint covering the columns `[name]` on the table `Anime` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateTable
CREATE TABLE "Subber" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL
);

-- CreateTable
CREATE TABLE "Torrent" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "title" TEXT NOT NULL,
    "link" TEXT NOT NULL,
    "pubDate" DATETIME NOT NULL,
    "guid" TEXT NOT NULL,
    "episode" INTEGER NOT NULL,
    "resolution" INTEGER NOT NULL,
    "extention" TEXT NOT NULL,
    "animeId" INTEGER NOT NULL,
    "subberId" INTEGER NOT NULL,
    FOREIGN KEY ("animeId") REFERENCES "Anime" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY ("subberId") REFERENCES "Subber" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "AutoDownload" (
    "animeId" INTEGER NOT NULL,
    "resolution" INTEGER NOT NULL,
    FOREIGN KEY ("animeId") REFERENCES "Anime" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateIndex
CREATE UNIQUE INDEX "Subber.name_unique" ON "Subber"("name");

-- CreateIndex
CREATE UNIQUE INDEX "Torrent.link_unique" ON "Torrent"("link");

-- CreateIndex
CREATE UNIQUE INDEX "AutoDownload.resolution_animeId_unique" ON "AutoDownload"("resolution", "animeId");

-- CreateIndex
CREATE UNIQUE INDEX "Anime.name_unique" ON "Anime"("name");
