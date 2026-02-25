import { ArrowLeft, Fingerprint } from "lucide-react";
import { MobileStatusBar } from "./MobileStatusBar";

interface MobileResetSentProps {
  onBack: () => void;
}

export function MobileResetSent({ onBack }: MobileResetSentProps) {
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
        <div className="text-center mb-12">
          <h2 className="text-xl text-black mb-3">Forgot password?</h2>
          <p className="text-gray-600 text-sm leading-relaxed">
            No worries, click the <span className="font-semibold">Reset</span> button and<br />
            an admin will get in touch with you.
          </p>
        </div>

        {/* Success Button */}
        <div className="w-full mb-8">
          <div className="w-full h-12 bg-gray-400 text-white rounded-lg flex items-center justify-center">
            RESET REQUEST SENT
          </div>
        </div>

        {/* Back to Login */}
        <button 
          onClick={onBack}
          className="flex items-center text-gray-600 text-sm hover:text-gray-800"
        >
          <ArrowLeft className="w-4 h-4 mr-2" />
          Back to Log in
        </button>
      </div>
    </div>
  );
}