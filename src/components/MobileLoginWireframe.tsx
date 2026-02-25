import { WireframeBox } from "./WireframeBox";
import logoImage from 'figma:asset/7106e387a0150aacb8a44d58c73d2158ededf89d.png';

export function MobileLoginWireframe() {
  return (
    <div className="w-80 bg-white border-2 border-gray-300 rounded-lg shadow-lg p-4">
      <div className="mb-4 text-center">
        <h3 className="text-sm mb-2">Mobile Login</h3>
        <div className="text-xs text-gray-500">375px × 812px</div>
      </div>
      
      <div className="space-y-4">
        {/* Status Bar */}
        <WireframeBox height="h-6" label="Status Bar">
          <div className="flex items-center justify-between w-full px-4">
            <div className="text-xs">9:41</div>
            <div className="flex space-x-1">
              <div className="w-4 h-2 bg-gray-300 rounded-sm"></div>
              <div className="w-4 h-2 bg-gray-300 rounded-sm"></div>
              <div className="w-4 h-2 bg-gray-300 rounded-sm"></div>
            </div>
          </div>
        </WireframeBox>

        {/* Logo and Branding */}
        <div className="flex flex-col items-center py-8 space-y-4">
          <div className="w-24 h-24 flex items-center justify-center">
            <img src={logoImage} alt="IMU Logo" className="w-20 h-20 object-contain" />
          </div>
          <div className="text-center">
            <div className="text-lg mb-1">IMU</div>
            <div className="text-xs text-gray-600">Itinerary Manager Uniformed</div>
          </div>
        </div>

        {/* Login Form */}
        <div className="space-y-3">
          <WireframeBox height="h-12" label="Email Input">
            <div className="flex items-center w-full px-4">
              <div className="w-4 h-4 bg-gray-300 rounded mr-3"></div>
              <div className="text-xs text-gray-500">Email address</div>
            </div>
          </WireframeBox>

          <WireframeBox height="h-12" label="Password Input">
            <div className="flex items-center justify-between w-full px-4">
              <div className="flex items-center">
                <div className="w-4 h-4 bg-gray-300 rounded mr-3"></div>
                <div className="text-xs text-gray-500">Password</div>
              </div>
              <div className="w-4 h-4 bg-gray-300 rounded"></div>
            </div>
          </WireframeBox>

          <WireframeBox height="h-12" label="Login Button" className="bg-gray-400 border-gray-500">
            <div className="text-xs text-white">Sign In</div>
          </WireframeBox>
        </div>

        {/* Additional Options */}
        <div className="space-y-3 pt-4">
          <div className="text-center">
            <div className="w-24 h-3 bg-gray-300 rounded mx-auto"></div>
            <div className="text-xs text-gray-500 mt-1">Forgot Password?</div>
          </div>

          {/* Divider */}
          <div className="flex items-center space-x-3">
            <div className="flex-1 h-px bg-gray-300"></div>
            <div className="text-xs text-gray-500">OR</div>
            <div className="flex-1 h-px bg-gray-300"></div>
          </div>

          {/* Social Login */}
          <WireframeBox height="h-12" label="Google Login">
            <div className="flex items-center justify-center space-x-2">
              <div className="w-5 h-5 bg-gray-300 rounded"></div>
              <div className="text-xs">Continue with Google</div>
            </div>
          </WireframeBox>

          {/* Sign Up Link */}
          <div className="text-center pt-4">
            <div className="text-xs text-gray-500">Don't have an account?</div>
            <div className="w-16 h-3 bg-gray-400 rounded mx-auto mt-1"></div>
          </div>
        </div>
      </div>
    </div>
  );
}