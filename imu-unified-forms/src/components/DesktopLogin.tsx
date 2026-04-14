import { useState } from "react";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import { Eye, EyeOff } from "lucide-react";
import { toast } from "sonner@2.0.3";
import logoImage from 'figma:asset/7106e387a0150aacb8a44d58c73d2158ededf89d.png';

interface DesktopLoginProps {
  onLogin: () => void;
}

export function DesktopLogin({ onLogin }: DesktopLoginProps) {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    
    // Simulate login process
    setTimeout(() => {
      if (username && password) {
        toast.success("Login successful! Welcome to IMU.");
        onLogin(); // Navigate to dashboard after successful login
      } else {
        toast.error("Please fill in all fields.");
      }
      setIsLoading(false);
    }, 1500);
  };

  return (
    <div className="w-full h-screen bg-white flex">
      {/* Left Side - Dark Background with Branding */}
      <div className="flex-1 bg-slate-800 text-white p-12 flex flex-col justify-between">
        {/* Header */}
        <div className="flex items-center space-x-4">
          <div className="w-8 h-8">
            <img src={logoImage} alt="IMU Logo" className="w-full h-full object-contain filter brightness-0 invert" />
          </div>
          <span className="text-lg">Itinerary Manager - Uniformed</span>
        </div>

        {/* Bottom Quote */}
        <div className="max-w-md">
          <p className="text-sm leading-relaxed">
            "The right financial support can transform lives. That's why we're dedicated to providing loans that are not just accessible, but also aligned with your long-term goals. You can trust that we're here to empower you with the resources you need to succeed, every step of the way."
          </p>
        </div>

        {/* Top Navigation */}
        <div className="absolute top-4 left-4 text-sm text-gray-300">
          Admin - Login
        </div>
      </div>

      {/* Right Side - Login Form */}
      <div className="w-[480px] bg-gray-50 flex items-center justify-center p-12">
        <div className="w-full max-w-sm">
          {/* Logo and Header */}
          <div className="text-center mb-8">
            <div className="w-12 h-12 mx-auto mb-4">
              <img src={logoImage} alt="IMU Logo" className="w-full h-full object-contain" />
            </div>
            <h2 className="text-xl text-black mb-2">Login to your account</h2>
            <p className="text-gray-600 text-sm">Enter your username and password</p>
          </div>

          {/* Login Form */}
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="username" className="text-black text-sm">Username</Label>
              <Input
                id="username"
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                placeholder="Username"
                className="w-full h-10 px-3 border border-gray-300 rounded bg-white text-black placeholder-gray-400"
                required
              />
            </div>

            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <Label htmlFor="password" className="text-black text-sm">Password</Label>
                <button 
                  type="button"
                  className="text-blue-600 text-sm hover:underline"
                >
                  Forgot your password?
                </button>
              </div>
              <div className="relative">
                <Input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Password"
                  className="w-full h-10 px-3 pr-10 border border-gray-300 rounded bg-white text-black placeholder-gray-400"
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400"
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            <div className="pt-4">
              <Button 
                type="submit" 
                className="w-full h-10 bg-slate-600 hover:bg-slate-700 text-white rounded"
                disabled={isLoading}
              >
                {isLoading ? "Logging in..." : "Continue"}
              </Button>
            </div>
          </form>

          {/* Footer */}
          <div className="text-center mt-6">
            <p className="text-gray-500 text-sm">
              Contact admin in case of forgotten credentials.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}