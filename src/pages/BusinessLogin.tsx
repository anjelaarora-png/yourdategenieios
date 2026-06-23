import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { ArrowLeft, Sparkles } from 'lucide-react'
import { cn } from '@/lib/utils'

const BusinessLogin = () => {
  const navigate = useNavigate()
  const [mode, setMode] = useState<'individual' | 'business'>('business')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')

  const inputClass = cn(
    'w-full rounded-lg border border-border bg-background/60 px-4 py-3 text-foreground placeholder:text-muted-foreground',
    'focus:outline-none focus:ring-2 focus:ring-primary/50'
  )

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (mode === 'business') {
      const q = new URLSearchParams({ src: 'business-login', email: email.trim() })
      navigate(`/for-business/apply?${q.toString()}`)
      return
    }
    navigate('/login')
  }

  return (
    <div className="min-h-screen bg-background flex flex-col">
      <header className="border-b border-border/60">
        <div className="container px-4 sm:px-6 py-4 flex items-center justify-between max-w-md mx-auto">
          <Link
            to="/"
            className="inline-flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground"
          >
            <ArrowLeft className="w-4 h-4" />
            Home
          </Link>
          <Sparkles className="w-4 h-4 text-primary" />
        </div>
      </header>

      <main className="flex-1 flex items-center justify-center px-4 py-10">
        <div className="w-full max-w-md">
          <div className="text-center mb-8">
            <div className="w-12 h-12 rounded-full bg-primary/10 border border-primary/20 flex items-center justify-center mx-auto mb-4 text-xl">
              🏪
            </div>
            <h1 className="font-display text-2xl text-foreground mb-2">
              {mode === 'business' ? 'Venue partner sign in' : 'Welcome back'}
            </h1>
            <p className="text-sm text-muted-foreground">
              {mode === 'business'
                ? 'Manage advertising & featured placement applications'
                : 'Sign in to plan date nights'}
            </p>
          </div>

          <div className="flex rounded-lg bg-muted/40 p-1 mb-6">
            <button
              type="button"
              onClick={() => setMode('individual')}
              className={cn(
                'flex-1 py-2 text-sm font-medium rounded-md transition-colors',
                mode === 'individual' ? 'bg-background text-primary shadow-sm' : 'text-muted-foreground'
              )}
            >
              Individual
            </button>
            <button
              type="button"
              onClick={() => setMode('business')}
              className={cn(
                'flex-1 py-2 text-sm font-medium rounded-md transition-colors',
                mode === 'business' ? 'bg-background text-primary shadow-sm' : 'text-muted-foreground'
              )}
            >
              Business
            </button>
          </div>

          <form onSubmit={handleSubmit} className="flex flex-col gap-3">
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder={mode === 'business' ? 'Business email' : 'Email'}
              className={inputClass}
            />
            <input
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Password"
              className={inputClass}
            />
            <button
              type="submit"
              className="rounded-lg bg-primary py-3.5 font-semibold text-primary-foreground hover:opacity-90 mt-2"
            >
              {mode === 'business' ? 'Continue to partner portal' : 'Sign in'}
            </button>
          </form>

          {mode === 'business' ? (
            <p className="text-center text-xs text-muted-foreground mt-4">
              New partner?{' '}
              <Link to="/for-business/apply" className="text-primary hover:underline">
                Apply without signing in
              </Link>
            </p>
          ) : (
            <p className="text-center text-xs text-muted-foreground mt-4">
              <Link to="/signup" className="text-primary hover:underline">
                Create account
              </Link>
            </p>
          )}

          {mode === 'business' && (
            <p className="text-center text-xs text-muted-foreground mt-3">
              <Link to="/login" className="hover:underline">
                ← Individual app sign in
              </Link>
            </p>
          )}
        </div>
      </main>
    </div>
  )
}

export default BusinessLogin
