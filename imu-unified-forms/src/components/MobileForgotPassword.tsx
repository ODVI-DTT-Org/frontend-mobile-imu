import { useState } from "react";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import { ArrowLeft, Fingerprint } from "lucide-react";
import { toast } from "sonner@2.0.3";
import { MobileStatusBar } from "./MobileStatusBar";

interface MobileForgotPasswordProps {
  onBack: () => void;
  onResetSent: () => void;
}

export function MobileForgotPassword({ onBack, onResetSent }: MobileForgotPasswordProps) {
  const [username, setUsername] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!username) {
      toast.error("Please enter your username.");
      return;
    }
    
    setIsLoading(true);
    
    // Simulate reset request
    setTimeout(() => {
      toast.success("Reset request sent!");
      setIsLoading(false);
      onResetSent();
    }, 1500);
  };

  return (
    <div className="w-[375px] h-[812px] bg-white flex flex-col">
      {/* Status Bar */}
      <MobileStatusBar />

      {/* Main Content */}
      <div className="flex-1 px-8 pt-16 pb-8 flex flex-col items-center">
        {/* Fingerprint Icon */}
        <div className="w-16 h-16 mb-8 flex items-center justify-center">
          <Fingerprint className="w-12 h-12 text-green-600" strokeWidth={1.5} />
        </div>

        {/* Title and Description */}
        <div className="text-center mb-8">
          <h2 className="text-xl text-black mb-3">Forgot password?</h2>
          <p className="text-gray-600 text-sm leading-relaxed">
            No worries, click the <span className="font-semibold">Reset</span> button and<br />
            an admin will get in touch with you.
          </p>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="w-full space-y-6">
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

          <div className="pt-2">
            <Button 
              type="submit" 
              className="w-full h-12 bg-slate-800 hover:bg-slate-900 text-white rounded-lg"
              disabled={isLoading}
            >
              {isLoading ? "SENDING..." : "RESET"}
            </Button>
          </div>
        </form>

        {/* Back to Login */}
        <button 
          onClick={onBack}
          className="flex items-center text-gray-600 text-sm mt-6 hover:text-gray-800"
        >
          <ArrowLeft className="w-4 h-4 mr-2" />
          Back to Log in
        </button>
      </div>
    </div>
  );
}