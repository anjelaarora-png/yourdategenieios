import { MapPin, Clock, Utensils, Music, Wine, Camera } from "lucide-react";

const samplePlans = [
  {
    title: "Sunset & Sips",
    tagline: "A golden hour adventure through Brooklyn's finest",
    stops: [
      { icon: Wine, name: "Rooftop Wine Bar", time: "6:00 PM" },
      { icon: Utensils, name: "Farm-to-Table Dinner", time: "7:30 PM" },
      { icon: Music, name: "Live Jazz Lounge", time: "9:30 PM" },
    ],
    duration: "4 hours",
    image: "https://images.unsplash.com/photo-1530103862676-de8c9debad1d?w=400&h=300&fit=crop",
  },
  {
    title: "Art & Appetite",
    tagline: "Culture meets cuisine in the heart of the city",
    stops: [
      { icon: Camera, name: "Gallery District Walk", time: "2:00 PM" },
      { icon: Utensils, name: "Hidden Gem Café", time: "4:00 PM" },
      { icon: Wine, name: "Speakeasy Cocktails", time: "6:00 PM" },
    ],
    duration: "5 hours",
    image: "https://images.unsplash.com/photo-1518998053901-5348d3961a04?w=400&h=300&fit=crop",
  },
  {
    title: "Moonlit Romance",
    tagline: "An evening designed for whispered conversations",
    stops: [
      { icon: Utensils, name: "Candlelit Italian", time: "7:00 PM" },
      { icon: MapPin, name: "Waterfront Stroll", time: "9:00 PM" },
      { icon: Wine, name: "Dessert & Champagne", time: "10:00 PM" },
    ],
    duration: "4 hours",
    image: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=300&fit=crop",
  },
];

const DatePlanPreviews = () => {
  return (
    <section className="py-24">
      <div className="container px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-2xl mx-auto mb-16">
          <h2 className="font-display text-3xl sm:text-4xl lg:text-5xl mb-4 text-foreground">
            Plans That <span className="text-primary">Wow</span>
          </h2>
          <p className="text-muted-foreground text-lg">
            Here's a taste of what your personalized date plans look like
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-6xl mx-auto">
          {samplePlans.map((plan, index) => (
            <div
              key={plan.title}
              className="group relative overflow-hidden rounded-xl bg-card border border-border hover:border-primary/50 transition-all duration-500 hover:shadow-xl hover:shadow-primary/10"
            >
              {/* Image header */}
              <div className="relative h-48 overflow-hidden">
                <img
                  src={plan.image}
                  alt={plan.title}
                  className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-card via-card/50 to-transparent" />
                <div className="absolute bottom-4 left-4 right-4">
                  <h3 className="font-display text-2xl text-foreground mb-1">{plan.title}</h3>
                  <p className="text-primary text-sm font-medium">{plan.tagline}</p>
                </div>
              </div>

              {/* Stops */}
              <div className="p-6 space-y-4">
                {plan.stops.map((stop, stopIndex) => (
                  <div key={stop.name} className="flex items-center gap-4">
                    <div className="relative">
                      <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                        <stop.icon className="w-5 h-5 text-primary" />
                      </div>
                      {stopIndex < plan.stops.length - 1 && (
                        <div className="absolute top-10 left-1/2 -translate-x-1/2 w-0.5 h-4 bg-border" />
                      )}
                    </div>
                    <div className="flex-1">
                      <p className="text-foreground font-medium">{stop.name}</p>
                      <p className="text-muted-foreground text-sm">{stop.time}</p>
                    </div>
                  </div>
                ))}

                {/* Duration badge */}
                <div className="flex items-center gap-2 pt-4 border-t border-border">
                  <Clock className="w-4 h-4 text-muted-foreground" />
                  <span className="text-muted-foreground text-sm">{plan.duration}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default DatePlanPreviews;
