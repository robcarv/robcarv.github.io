// Contains constant data for using in website
// ! Don't remove anything from here if not sure

import {
  mobile,
  backend,
  creator,
  web,
  javascript,
  typescript,
  html,
  css,
  reactjs,
  redux,
  tailwind,
  nodejs,
  mongodb,
  git,
  figma,
  docker,
  meta,
  starbucks,
  tesla,
  shopify,
  threejs,
  project1,
  project2,
  project3,
  project4,
  project5,
  project6,
  user1,
  user2,
  user3,
  youtube,
  linkedin,
  twitter,
  github,
} from "../assets";

// Navbar Links
export const NAV_LINKS = [
  {
    id: "about",
    title: "About",
    link: null,
  },
  {
    id: "work",
    title: "Work",
    link: null,
  },
  {
    id: "projects",
    title: "Projects",
    link: null,
  },
  {
    id: "contact",
    title: "Contact",
    link: null,
  },
  {
    id: "source-code",
    title: "Source Code",
    link: "https://github.com/robcarv/robcarv.github.io",
  },
] as const;

// Services
export const SERVICES = [
  {
    title: "QA Automation Engineer",
    icon: web,
  },
  {
    title: "Python Developer",
    icon: mobile,
  },
  {
    title: "Infrastructure",
    icon: backend,
  },
  {
    title: "Homelab Builder",
    icon: creator,
  },
] as const;

// Technologies
export const TECHNOLOGIES = [
  {
    name: "Python",
    icon: html,
  },
  {
    name: "Java",
    icon: css,
  },
  {
    name: "JavaScript",
    icon: javascript,
  },
  {
    name: "TypeScript",
    icon: typescript,
  },
  {
    name: "React JS",
    icon: reactjs,
  },
  {
    name: "Docker",
    icon: docker,
  },
  {
    name: "Playwright",
    icon: nodejs,
  },
  {
    name: "Linux",
    icon: mongodb,
  },
  {
    name: "Three JS",
    icon: threejs,
  },
  {
    name: "git",
    icon: git,
  },
  {
    name: "Tailwind CSS",
    icon: tailwind,
  },
  {
    name: "figma",
    icon: figma,
  },
] as const;

// Experiences
export const EXPERIENCES = [
  {
    title: "QA Automation Engineer",
    company_name: "IBM",
    icon: meta,
    iconBg: "#383E56",
    date: "Present",
    points: [
      "Automating E2E tests with Python + Playwright for enterprise web applications",
      "Building and maintaining CI/CD pipelines with Azure DevOps",
      "Creating test frameworks and reporting tools for QA teams",
      "Collaborating with developers to ensure quality across releases",
    ],
  },
  {
    title: "Homelab Architect",
    company_name: "Self-Hosted",
    icon: starbucks,
    iconBg: "#E6DEDD",
    date: "2024 - Present",
    points: [
      "Cluster of 3 Raspberry Pis running 25+ Docker containers",
      "TrueNAS Scale with 10.9TB NVMe storage for media pipeline",
      "Automated backup system with ClamAV antivirus and Git push",
      "UptimeKuma monitoring 55+ services with alerting",
    ],
  },
  {
    title: "Full Stack Developer",
    company_name: "Freelance",
    icon: shopify,
    iconBg: "#383E56",
    date: "2023 - Present",
    points: [
      "Built news aggregation bot with RSS + LLM + TTS pipeline",
      "Developed custom AzuraCast radio station with glassmorphism UI",
      "Created Docker-based media pipeline (Radarr → qBittorrent → ClamAV → Jellyfin)",
      "Designed and deployed monitoring dashboards with Dashy and UptimeKuma",
    ],
  },
] as const;

// Testimonials
export const TESTIMONIALS = [
  {
    testimonial:
      "A homelab that would make most IT departments jealous — 3 Pis, 55+ services monitored, and automated backups with antivirus.",
    name: "Dublin Calling",
    designation: "Radio Station",
    company: "AzuraCast",
    image: user1,
  },
  {
    testimonial:
      "From RSS feeds to Telegram in minutes — the NewsBot pipeline uses LLMs to summarize articles and TTS to read them aloud.",
    name: "News Collector",
    designation: "Automation",
    company: "Python",
    image: user2,
  },
  {
    testimonial:
      "Enterprise-grade QA automation with Python + Playwright, running tests across browsers and APIs with detailed reporting.",
    name: "Test Framework",
    designation: "QA Pipeline",
    company: "IBM",
    image: user3,
  },
] as const;

// Projects
export const PROJECTS = [
  {
    name: "Homelab Cluster",
    description:
      "3× Raspberry Pi cluster with TrueNAS storage, Docker orchestration, 55+ monitored services, automated backups with ClamAV, and Git push. Load-balanced after Pi5 crash analysis.",
    tags: [
      {
        name: "docker",
        color: "blue-text-gradient",
      },
      {
        name: "raspberrypi",
        color: "green-text-gradient",
      },
      {
        name: "truenas",
        color: "pink-text-gradient",
      },
    ],
    image: project1,
    source_code_link: "https://github.com/robcarv/backup_raspberry",
  },
  {
    name: "News Collector Bot",
    description:
      "RSS feed aggregator that uses LLM to summarize articles and edge-tts/TTS to generate audio, delivering news via Telegram. Automatically pushes logs and history to GitHub.",
    tags: [
      {
        name: "python",
        color: "blue-text-gradient",
      },
      {
        name: "rss",
        color: "green-text-gradient",
      },
      {
        name: "telegram",
        color: "pink-text-gradient",
      },
    ],
    image: project2,
    source_code_link: "https://github.com/robcarv/news_colletector",
  },
  {
    name: "Dublin Calling Radio",
    description:
      "Digital radio station built on AzuraCast with custom glassmorphism UI, real-time now playing via API, Liquidsoap streaming, and MariaDB backend.",
    tags: [
      {
        name: "azuracast",
        color: "blue-text-gradient",
      },
      {
        name: "liquidsoap",
        color: "green-text-gradient",
      },
      {
        name: "radio",
        color: "pink-text-gradient",
      },
    ],
    image: project3,
    source_code_link: null,
  },
  {
    name: "Media Pipeline",
    description:
      "Full automated media pipeline: Prowlarr → Radarr → qBittorrent → ClamAV scan → Jellyfin. With health checks every 2h and daily antivirus scans.",
    tags: [
      {
        name: "prowlarr",
        color: "blue-text-gradient",
      },
      {
        name: "radarr",
        color: "green-text-gradient",
      },
      {
        name: "jellyfin",
        color: "pink-text-gradient",
      },
    ],
    image: project4,
    source_code_link: "https://github.com/robcarv/dashy-homelab",
  },
  {
    name: "Dashy Dashboard",
    description:
      "Central homelab dashboard with 30+ service links, status checks, and live radio player. Deployed on 2 Pis with Nginx Proxy Manager for SSL.",
    tags: [
      {
        name: "dashy",
        color: "blue-text-gradient",
      },
      {
        name: "nginx",
        color: "green-text-gradient",
      },
      {
        name: "docker",
        color: "pink-text-gradient",
      },
    ],
    image: project5,
    source_code_link: "https://github.com/robcarv/dashy-homelab",
  },
] as const;

// Social Links
export const SOCIALS = [
  {
    name: "GitHub",
    icon: github,
    link: "https://github.com/robcarv",
  },
  {
    name: "LinkedIn",
    icon: linkedin,
    link: "https://linkedin.com/in/rac-carvalho",
  },
  {
    name: "YouTube",
    icon: youtube,
    link: "https://www.youtube.com/@dublincalling",
  },
] as const;
