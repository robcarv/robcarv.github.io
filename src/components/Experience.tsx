import { EXPERIENCES } from '@/lib/types'

export default function Experience() {
  return (
    <section className="py-16 px-4">
      <div className="max-w-3xl mx-auto">
        <h2 className="text-2xl font-bold text-white mb-10">Experience</h2>

        <div className="relative">
          {/* Vertical line */}
          <div className="absolute left-4 top-0 bottom-0 w-px bg-gray-800" />

          <div className="space-y-10">
            {EXPERIENCES.map((exp, idx) => (
              <div key={idx} className="relative pl-12">
                {/* Timeline dot */}
                <div className="absolute left-2.5 top-1.5 w-3 h-3 rounded-full bg-emerald-500 border-2 border-gray-950 ring-2 ring-gray-800 z-10" />

                {/* Card */}
                <div className="rounded-xl border border-gray-800 bg-gray-900/50 p-5 hover:border-gray-700 transition-colors">
                  <h3 className="text-base font-bold text-white">{exp.role}</h3>
                  <p className="text-sm text-emerald-400 mt-0.5">{exp.company}</p>
                  <p className="text-xs text-gray-500 mt-1 mb-3">{exp.period}</p>

                  <ul className="space-y-1.5">
                    {exp.items.map((item, i) => (
                      <li key={i} className="flex items-start gap-2 text-sm text-gray-400">
                        <span className="mt-1.5 w-1.5 h-1.5 rounded-full bg-gray-600 flex-shrink-0" />
                        {item}
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}
