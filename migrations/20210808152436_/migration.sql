/*
  Warnings:

  - You are about to drop the `AnimeSubbers` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropTable
PRAGMA foreign_keys=off;
DROP TABLE "AnimeSubbers";
PRAGMA foreign_keys=on;

-- CreateTable
CREATE TABLE "AnimeSubber" (
    "animeName" TEXT NOT NULL,
    "subberName" TEXT NOT NULL,
    "autodownload" BOOLEAN NOT NULL DEFAULT false,

    PRIMARY KEY ("animeName", "subberName"),
    FOREIGN KEY ("animeName") REFERENCES "Anime" ("name") ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY ("subberName") REFERENCES "Subber" ("name") ON DELETE CASCADE ON UPDATE CASCADE
);
