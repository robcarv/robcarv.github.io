import Hero from "@/components/Hero";
import Experience from "@/components/Experience";
import HomeLabStatus from "@/components/HomeLabStatus";
import NewsFeed from "@/components/NewsFeed";
import RadioPlayer from "@/components/RadioPlayer";
import Projects from "@/components/Projects";

export default function HomePt() {
  return (
    <div className="max-w-6xl mx-auto px-4 py-8 space-y-16">
      <Hero />
      <HomeLabStatus />
      <Experience />
      <Projects />
      <NewsFeed />
      <RadioPlayer />
    </div>
  );
}
