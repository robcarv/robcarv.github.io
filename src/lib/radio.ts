export interface NowPlaying {
  title: string
  artist: string
  album: string
  art_url: string
  listeners: number
}

export async function getNowPlaying(): Promise<NowPlaying | null> {
  return null
}
