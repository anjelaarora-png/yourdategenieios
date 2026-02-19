import Navbar from "@/components/layout/Navbar";
import HeroSection from "@/components/landing/HeroSection";
import Features from "@/components/landing/Features";
import DatePlanPreviews from "@/components/landing/DatePlanPreviews";
import Testimonials from "@/components/landing/Testimonials";
import HowItWorks from "@/components/landing/HowItWorks";
import Pricing from "@/components/landing/Pricing";
import Footer from "@/components/landing/Footer";
import FloatingCTA from "@/components/landing/FloatingCTA";

const Index = () => {
  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      <main>
        <HeroSection />
        <Features />
        <DatePlanPreviews />
        <Testimonials />
        <HowItWorks />
        <Pricing />
      </main>
      <Footer />
      <FloatingCTA />
    </div>
  );
};

export default Index;
