import { Link } from "react-router-dom";
import logo from "@/assets/logo.png";

interface LogoProps {
  size?: "sm" | "md" | "lg";
  showText?: boolean;
}

const Logo = ({ size = "md", showText = true }: LogoProps) => {
  const sizes = {
    sm: "h-8",
    md: "h-12",
    lg: "h-20",
  };

  return (
    <Link to="/" className="flex items-center gap-3">
      <img src={logo} alt="Your Date Genie" className={`${sizes[size]} w-auto`} />
    </Link>
  );
};

export default Logo;
