import { useState } from "react";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import { Eye, EyeOff } from "lucide-react";
import { toast } from "sonner@2.0.3";
import logoImage from 'figma:asset/7106e387a0150aacb8a44d58c73d2158ededf89d.png';
import { MobileStatusBar } from "./MobileStatusBar";

interface MobileLoginProps {
  onForgotPassword: () => void;
  onLoginSuccess: () => void;
}

export function MobileLogin({ onForgotPassword, onLoginSuccess }: MobileLoginProps) {
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
        onLoginSuccess();
      } else {
        toast.error("Please fill in all fields.");
      }
      setIsLoading(false);
    }, 1500);
  };

  return (
    <div className="w-[375px] h-[812px] bg-white flex flex-col">
      {/* Status Bar */}
      <MobileStatusBar />

      {/* Main Content */}
      <div className="flex-1 px-8 pt-16 pb-8">
        {/* Logo and Branding */}
        <div className="flex flex-col items-center mb-12">
          <div className="w-16 h-16 mb-6">
            <img src={logoImage} alt="IMU Logo" className="w-full h-full object-contain" />
          </div>
          <h1 className="text-xl text-black mb-2">Itinerary Manager - Uniformed</h1>
          <p className="text-gray-600 text-center text-sm">
            Please enter your details to login.
          </p>
        </div>

        {/* Login Form */}
        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="space-y-2">
            <Label htmlFor="username" className="text-black text-sm">Username</Label>
            <Input
              id="username"
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              placeholder="mreyes"
              className="w-full h-12 px-4 border border-gray-300 rounded-lg bg-white text-black placeholder-gray-400"
              required
            />
          </div>

          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <Label htmlFor="password" className="text-black text-sm">Password</Label>
              <button 
                type="button"
                onClick={onForgotPassword}
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
                placeholder="password1234"
                className="w-full h-12 px-4 pr-12 border border-gray-300 rounded-lg bg-white text-black placeholder-gray-400"
                required
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-4 top-1/2 transform -translate-y-1/2 text-gray-400"
              >
                {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
              </button>
            </div>
          </div>

          <div className="pt-4">
            <Button 
              type="submit" 
              className="w-full h-12 bg-slate-700 hover:bg-slate-800 text-white rounded-lg"
              disabled={isLoading}
            >
              {isLoading ? "LOGGING IN..." : "LOGIN"}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}