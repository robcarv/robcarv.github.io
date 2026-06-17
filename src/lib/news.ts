export interface NewsItem {
  title: string
  url: string
  source: string
  published: string
}

export interface NewsData {
  updated: string
  items: NewsItem[]
}

export async function getNews(): Promise<NewsData> {
  return { updated: new Date().toISOString(), items: [] }
}

export function getSourceColor(source: string): string {
  const colors: Record<string, string> = {
    'The Guardian US': 'from-blue-600 to-blue-800',
    'The Guardian Tech': 'from-blue-500 to-blue-700',
    'BBC News': 'from-red-600 to-red-800',
    'Folha de S.Paulo': 'from-yellow-600 to-yellow-800',
    'Irish Independent': 'from-green-600 to-green-800',
    'Hot Press (Ireland)': 'from-purple-600 to-purple-800',
    'MusicRadar (UK)': 'from-pink-600 to-pink-800',
    'Rolling Stone Music (US)': 'from-orange-600 to-orange-800',
  }
  return colors[source] || 'from-gray-600 to-gray-800'
}
