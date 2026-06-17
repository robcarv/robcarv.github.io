export interface Experience {
  role: string
  company: string
  period: string
  items: string[]
}

export interface Project {
  name: string
  description: string
  url?: string
  github?: string
}

export const EXPERIENCES: Experience[] = [
  {
    role: 'QA Automation Engineer',
    company: 'IBM',
    period: 'Oct 2021 — Present',
    items: [
      'Automated testing frameworks with Python, Java, and Playwright',
      'CI/CD pipeline management using GitHub Actions and Jenkins',
      'API testing, contract testing, and end-to-end test suites',
      'Cross-functional collaboration with development and product teams'
    ]
  },
  {
    role: 'Support Engineer',
    company: 'TOTVS',
    period: 'Oct 2015 — Oct 2021',
    items: [
      'Technical support and troubleshooting for enterprise ERP systems',
      'Database analysis and performance tuning in SQL Server and PostgreSQL',
      'Customer-facing incident resolution and root cause analysis'
    ]
  },
  {
    role: 'Support Engineer',
    company: 'Avis Budget Group',
    period: 'May 2012 — Mar 2015',
    items: [
      'IT support for 200+ users across multiple European locations',
      'System administration and network infrastructure maintenance',
      'Hardware and software lifecycle management'
    ]
  }
]

export const PROJECTS: Project[] = [
  {
    name: 'Homelab Cluster',
    description: '3 Raspberry Pis + TrueNAS, 55+ Docker services, automated CI/CD',
    url: '/homelab',
    github: 'https://github.com/robcarv/backup_raspberry'
  },
  {
    name: 'Gallery Downloader',
    description: 'Self-hosted media downloader with Go backend + React frontend',
    github: 'https://github.com/robcarv/backup_raspberry/tree/mangadownloader-v4'
  },
  {
    name: 'News Collector Bot',
    description: 'Automated RSS news collection, summarization and portfolio publishing',
    github: 'https://github.com/robcarv/news_colletector'
  },
  {
    name: 'Dublin Calling Radio',
    description: 'Irish music radio station automation and streaming platform',
    url: 'https://dublincalling.ie'
  },
  {
    name: 'Dashy Dashboard',
    description: 'Self-hosted service dashboard for homelab monitoring',
    github: 'https://github.com/robcarv/dashy-config'
  },
  {
    name: 'Media Server',
    description: 'Jellyfin + Komga + Kavita media streaming stack on TrueNAS',
    url: '/homelab-architecture'
  }
]
