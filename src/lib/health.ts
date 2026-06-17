export interface NodeStatus {
  status: 'ok' | 'warn' | 'fail'
  cpu: string
  ram: string
  ram_gb: string
  ram_total: string
  uptime: string
  load: string
  services: string
}

export interface RadioData {
  station: string
  is_online: boolean
  is_live: boolean
  now_playing: {
    title: string
    artist: string
    album: string
    art: string
    text: string
    duration: number
    elapsed: number
  }
  playing_next: {
    title: string
    artist: string
  }
  listeners: number
  history: Array<{
    title: string
    artist: string
    played_at: number
  }>
  listen_url: string
}

export interface HealthData {
  updated: string
  status: 'ok' | 'warn' | 'fail'
  nodes: Record<string, NodeStatus>
  radio?: RadioData
}

export async function getHealth(): Promise<HealthData> {
  return {
    updated: new Date().toISOString(),
    status: 'warn',
    nodes: {},
    radio: undefined
  }
}
