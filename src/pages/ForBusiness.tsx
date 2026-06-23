import { useSearchParams, Link } from 'react-router-dom'
import { Sparkles, MapPin, Users, TrendingUp, ArrowLeft } from 'lucide-react'
import { BusinessListingForm } from '@/components/business/BusinessListingForm'

const BENEFITS = [
  {
    icon: Users,
    title: 'Couples already planning',
    text: 'Show up inside AI date itineraries when Genie matches your city, vibe, and category — restaurants, bars, experiences, retail, and more.',
  },
  {
    icon: MapPin,
    title: 'Local, intent-rich traffic',
    text: 'Not random clicks — couples searching cozy cocktails, live music, adventure dates, or a quiet dinner near them.',
  },
  {
    icon: TrendingUp,
    title: 'Launch partner rates',
    text: 'Early venues get featured placement pricing before we open self-serve ads.',
  },
]

const ForBusiness = () => {
  const [searchParams] = useSearchParams()
  const source = searchParams.get('src') ?? 'direct'

  return (
    <div className="min-h-screen bg-background flex flex-col">
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/4 right-1/4 w-[280px] h-[280px] bg-primary/8 rounded-full blur-3xl animate-pulse" />
        <div
          className="absolute bottom-1/4 left-1/4 w-[220px] h-[220px] bg-primary/5 rounded-full blur-3xl animate-pulse"
          style={{ animationDelay: '1s' }}
        />
      </div>

      <header className="relative z-10 border-b border-border/60">
        <div className="container px-4 sm:px-6 lg:px-8 py-4 flex items-center justify-between gap-4">
          <Link
            to="/"
            className="inline-flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground transition-colors"
          >
            <ArrowLeft className="w-4 h-4" />
            Back to home
          </Link>
          <div className="flex items-center gap-2">
            <Sparkles className="w-4 h-4 text-primary" />
            <span className="font-display text-lg text-foreground">For Business</span>
          </div>
        </div>
      </header>

      <main className="flex-1 relative z-10">
        <div className="container px-4 sm:px-6 lg:px-8 py-12 lg:py-16">
          <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-start max-w-6xl mx-auto">
            <div>
              <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-primary/10 border border-primary/20 mb-5">
                <span className="w-2 h-2 rounded-full bg-primary animate-pulse" />
                <span className="text-primary text-xs font-semibold uppercase tracking-wider">
                  Venue partners · launching 2026
                </span>
              </div>

              <h1 className="font-display text-3xl sm:text-4xl lg:text-5xl text-foreground mb-4 leading-tight">
                Put your date night spot in front of{' '}
                <span className="text-gradient-gold">couples who are ready to go</span>
              </h1>

              <p className="text-muted-foreground text-base sm:text-lg mb-8 leading-relaxed max-w-xl">
                Your Date Genie plans full evenings for couples — any date-night category, not just one
                cuisine or venue type. Apply to be featured when we match your city, vibe, and what you
                offer.
              </p>

              <div className="flex flex-col sm:flex-row gap-3 mb-8">
                <Link
                  to="/for-business/login"
                  className="inline-flex items-center justify-center rounded-lg bg-primary px-5 py-3 text-sm font-semibold text-primary-foreground hover:opacity-90 transition-opacity"
                >
                  Partner sign in
                </Link>
                <Link
                  to="/for-business/apply"
                  className="inline-flex items-center justify-center rounded-lg border border-primary/40 px-5 py-3 text-sm font-medium text-primary hover:bg-primary/10 transition-colors"
                >
                  Apply for advertising
                </Link>
              </div>

              <ul className="space-y-5 mb-8">
                {BENEFITS.map(({ icon: Icon, title, text }) => (
                  <li key={title} className="flex gap-4">
                    <span className="flex-shrink-0 w-10 h-10 rounded-xl bg-primary/10 border border-primary/20 flex items-center justify-center">
                      <Icon className="w-5 h-5 text-primary" />
                    </span>
                    <div>
                      <p className="font-medium text-foreground">{title}</p>
                      <p className="text-sm text-muted-foreground mt-1 leading-relaxed">{text}</p>
                    </div>
                  </li>
                ))}
              </ul>

              <p className="text-sm text-muted-foreground leading-relaxed">
                Questions? Email{' '}
                <a href="mailto:hello@yourdategenie.com" className="text-primary hover:underline">
                  hello@yourdategenie.com
                </a>{' '}
                with subject line <strong className="text-foreground font-normal">Venue partner</strong>.
              </p>
            </div>

            <div className="rounded-2xl border border-border bg-card/60 backdrop-blur-sm p-6 sm:p-8 shadow-xl lg:sticky lg:top-24">
              <h2 className="font-display text-xl sm:text-2xl text-foreground mb-2">
                Quick apply
              </h2>
              <p className="text-sm text-muted-foreground mb-4 leading-relaxed">
                For the full partner experience — onboarding, detailed application, and Firebase
                tracking — use the portal.
              </p>
              <Link
                to="/for-business/apply"
                className="flex items-center justify-center gap-2 rounded-lg bg-primary px-6 py-3.5 font-semibold text-primary-foreground w-full hover:opacity-90 mb-6"
              >
                Open partner portal →
              </Link>
              <p className="text-xs text-muted-foreground mb-4 text-center">or apply inline below</p>
              <BusinessListingForm source={source} />
              <p className="mt-5 text-xs text-muted-foreground text-center leading-relaxed">
                By submitting, you agree we may contact you about partnership and advertising on Your
                Date Genie. We won't sell your info.
              </p>
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}

export default ForBusiness
