#!/usr/bin/env python3
"""
AzuraCast Metadata Enricher + Portfolio Updater
===============================================
Busca a música atual no AzuraCast, enriquece com Last.fm + MusicBrainz
e salva metadados enriquecidos para o portfolio.

Uso:
    python3 azura_metadata.py              # Normal (cache de 30s)
    python3 azura_metadata.py --force      # Força atualização
"""

import json, os, sys, time, logging
from datetime import datetime
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.parse import urlencode

# ─── CONFIG ────────────────────────────────────────
AZURACAST_URL = "https://dublincalling.duckdns.org"
STATION = "dublincalling"
NOWPLAYING_API = f"{AZURACAST_URL}/api/nowplaying/{STATION}"
PORTFOLIO_DIR = "/home/robert/Documents/portfolio-html"
CACHE_FILE = "/tmp/azura_metadata_cache.json"
CACHE_TTL = 30  # segundos

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')
logger = logging.getLogger("azura_meta")

def fetch_json(url, timeout=10):
    try:
        req = Request(url, headers={"User-Agent": "DublinCalling/1.0"})
        with urlopen(req, timeout=timeout) as r:
            return json.loads(r.read())
    except Exception as e:
        logger.warning(f"Erro ao buscar {url}: {e}")
        return None

def search_lastfm(artist, title):
    """Busca metadados no Last.fm"""
    api_key = "aed5cf7a583df575c2c6868b442f1139"
    url = f"https://ws.audioscrobbler.com/2.0/?method=track.getInfo&api_key={api_key}&artist={urlencode({'':artist})[1:]}&track={urlencode({'':title})[1:]}&format=json&autocorrect=1"
    data = fetch_json(url)
    if data and 'track' in data:
        track = data['track']
        album = track.get('album', {})
        return {
            'album': album.get('title', ''),
            'artist': track.get('artist', {}).get('name', artist),
            'duration': track.get('duration', 0),
            'genre': ', '.join(g.get('name','') for g in track.get('toptags', {}).get('tag', [])[:3]) if 'toptags' in track else '',
            'playcount': track.get('playcount', 0),
            'listeners': track.get('listeners', 0)
        }
    return None

def get_metadata():
    """Busca metadados completos da música atual"""
    # Cache
    if os.path.exists(CACHE_FILE):
        age = time.time() - os.path.getmtime(CACHE_FILE)
        if age < CACHE_TTL:
            with open(CACHE_FILE) as f:
                return json.load(f)
    
    # Busca now playing do AzuraCast
    np_data = fetch_json(NOWPLAYING_API)
    if not np_data:
        return None
    
    if isinstance(np_data, list):
        np_data = np_data[0]
    
    now_playing = np_data.get('now_playing', {})
    song = now_playing.get('song', {})
    listeners = np_data.get('listeners', {}).get('current', 0)
    station = np_data.get('station', {})
    live = np_data.get('live', {})
    playing_next = np_data.get('playing_next', {})
    song_history = np_data.get('song_history', [])
    
    result = {
        'timestamp': datetime.now().isoformat(),
        'station': station.get('name', 'Dublin Calling'),
        'listeners': listeners,
        'is_live': live.get('is_live', False),
        'now_playing': {
            'title': song.get('title', 'Unknown'),
            'artist': song.get('artist', ''),
            'album': song.get('album', ''),
            'art': song.get('art', ''),
            'genre': song.get('genre', ''),
            'duration': now_playing.get('duration', 0),
            'elapsed': now_playing.get('elapsed', 0),
            'remaining': now_playing.get('remaining', 0),
            'playlist': now_playing.get('playlist', ''),
        },
        'playing_next': playing_next.get('song', {}),
        'history': [{
            'title': s.get('song', {}).get('title', ''),
            'artist': s.get('song', {}).get('artist', ''),
            'art': s.get('song', {}).get('art', ''),
            'played_at': s.get('played_at', 0)
        } for s in song_history[:5]],
    }
    
    # Enriquece com Last.fm (se tiver artista e título)
    if song.get('artist') and song.get('title'):
        meta = search_lastfm(song['artist'], song['title'])
        if meta:
            result['now_playing'].update({
                'album': meta.get('album', result['now_playing']['album']),
                'genre': meta.get('genre', result['now_playing']['genre']),
                'listeners_lastfm': meta.get('listeners', 0),
                'playcount_lastfm': meta.get('playcount', 0),
            })
    
    # Salva cache
    with open(CACHE_FILE, 'w') as f:
        json.dump(result, f)
    
    return result

def save_portfolio_metadata(meta):
    """Salva metadados no formato do portfolio"""
    if not meta:
        return
    
    np = meta['now_playing']
    data = {
        'updated': meta['timestamp'],
        'station': meta['station'],
        'listeners': meta['listeners'],
        'is_live': meta['is_live'],
        'now_playing': {
            'title': np['title'],
            'artist': np['artist'],
            'album': np['album'],
            'art': np.get('art', np.get('art', '')),
            'genre': np.get('genre', ''),
            'duration': np.get('duration', 0),
            'elapsed': np.get('elapsed', 0),
            'remaining': np.get('remaining', 0),
            'playlist': np.get('playlist', ''),
        },
        'playing_next': meta['playing_next'],
        'history': meta['history'],
    }
    
    path = Path(PORTFOLIO_DIR) / "radio_metadata.json"
    with open(path, 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    
    logger.info(f"✅ Metadados salvos em {path}")
    logger.info(f"   Tocando: {np['title']} - {np['artist']}")
    logger.info(f"   Album: {np['album']}")
    logger.info(f"   Ouvintes: {meta['listeners']}")

if __name__ == '__main__':
    force = '--force' in sys.argv
    if force:
        CACHE_TTL = 0
    
    meta = get_metadata()
    if meta:
        save_portfolio_metadata(meta)
        print(f"🎵 {meta['now_playing']['title']} - {meta['now_playing']['artist']}")
        print(f"👥 {meta['listeners']} ouvintes")
    else:
        print("❌ Erro ao buscar metadados")
        sys.exit(1)
