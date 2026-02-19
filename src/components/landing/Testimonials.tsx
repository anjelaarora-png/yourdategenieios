import { Star, Quote, ArrowRight, Heart } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Link } from "react-router-dom";

const testimonials = [
  {
    name: "Sarah & Michael",
    location: "New York, NY",
    image: "https://images.unsplash.com/photo-1522556189639-b150ed9c4330?w=200&h=200&fit=crop&crop=faces",
    quote: "We went from 'Netflix and leftover pizza' to a sunset rooftop dinner and jazz bar. Our friends think we have a secret planner!",
    rating: 5,
  },
  {
    name: "Jessica & David",
    location: "Los Angeles, CA",
    image: "https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?w=200&h=200&fit=crop&crop=faces",
    quote: "The Genie knew about my gluten allergy AND found a speakeasy my husband had been dying to try. Pure magic.",
    rating: 5,
  },
  {
    name: "Amanda & Chris",
    location: "Chicago, IL",
    image: "https://images.unsplash.com/photo-1621112904887-419379ce6824?w=200&h=200&fit=crop&crop=faces",
    quote: "Date night used to feel like a chore to plan. Now it's the highlight of our week. We've discovered so many hidden gems!",
    rating: 5,
  },
];

const Testimonials = () => {
  return (
    <section className="py-16 sm:py-24 bg-secondary/30">
      <div className="container px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-2xl mx-auto mb-10 sm:mb-16">
          <h2 className="font-display text-2xl sm:text-3xl md:text-4xl lg:text-5xl mb-4 text-foreground">
            Couples <span className="text-primary">Love</span> Us
          </h2>
          <p className="text-muted-foreground text-base sm:text-lg">
            Real stories from real couples who rekindled the spark
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 sm:gap-8 max-w-6xl mx-auto">
          {testimonials.map((testimonial, index) => (
            <div
              key={testimonial.name}
              className="relative p-6 sm:p-8 rounded-xl bg-card border border-border hover:border-primary/30 transition-all duration-300 group"
            >
              {/* Quote icon */}
              <Quote className="absolute top-4 sm:top-6 right-4 sm:right-6 w-6 h-6 sm:w-8 sm:h-8 text-primary/20 group-hover:text-primary/40 transition-colors" />
              
              {/* Stars */}
              <div className="flex gap-1 mb-3 sm:mb-4">
                {Array.from({ length: testimonial.rating }).map((_, i) => (
                  <Star key={i} className="w-4 h-4 fill-primary text-primary" />
                ))}
              </div>

              {/* Quote */}
              <p className="text-foreground text-base sm:text-lg mb-4 sm:mb-6 leading-relaxed italic">
                "{testimonial.quote}"
              </p>

              {/* Author */}
              <div className="flex items-center gap-3 sm:gap-4">
                <img
                  src={testimonial.image}
                  alt={testimonial.name}
                  className="w-10 h-10 sm:w-12 sm:h-12 rounded-full object-cover border-2 border-primary/30"
                />
                <div>
                  <p className="font-display text-foreground text-sm sm:text-base">{testimonial.name}</p>
                  <p className="text-muted-foreground text-xs sm:text-sm">{testimonial.location}</p>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* CTA after testimonials */}
        <div className="mt-12 sm:mt-16 text-center">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 border border-primary/20 mb-6">
            <Heart className="w-4 h-4 text-primary fill-primary" />
            <span className="text-primary text-sm font-medium">Join 500+ happy couples</span>
          </div>
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
            <Button 
              asChild 
              size="lg" 
              className="gradient-gold text-primary-foreground font-semibold px-8 py-6 text-base sm:text-lg glow-gold hover:opacity-90 transition-all hover:scale-105 group w-full sm:w-auto"
            >
              <Link to="/signup">
                Plan Your Date Now
                <ArrowRight className="ml-2 w-5 h-5 group-hover:translate-x-1 transition-transform" />
              </Link>
            </Button>
            <p className="text-muted-foreground text-sm">Free to start • No credit card</p>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Testimonials;
