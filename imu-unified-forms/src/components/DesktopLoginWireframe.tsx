import { WireframeBox } from "./WireframeBox";
import logoImage from 'figma:asset/7106e387a0150aacb8a44d58c73d2158ededf89d.png';

export function DesktopLoginWireframe() {
  return (
    <div className="w-full max-w-5xl bg-white border-2 border-gray-300 rounded-lg shadow-lg p-6">
      <div className="mb-4 text-center">
        <h3 className="text-sm mb-2">Desktop Login</h3>
        <div className="text-xs text-gray-500">1200px × 800px</div>
      </div>
      
      <div className="flex h-96">
        {/* Left Side - Branding */}
        <div className="flex-1 bg-gradient-to-br from-gray-100 to-gray-200 p-8 flex flex-col justify-center items-center rounded-l-lg">
          <WireframeBox width="w-full" height="h-full" label="Brand Section" className="bg-transparent border-gray-300">
            <div className="flex flex-col items-center space-y-6">
              <div className="w-32 h-32 flex items-center justify-center">
                <img src={logoImage} alt="IMU Logo" className="w-28 h-28 object-contain" />
              </div>
              <div className="text-center">
                <div className="text-2xl mb-2">IMU</div>
                <div className="text-sm text-gray-600 mb-4">Itinerary Manager Uniformed</div>
                <div className="w-64 h-4 bg-gray-300 rounded mx-auto mb-2"></div>
                <div className="w-48 h-3 bg-gray-300 rounded mx-auto mb-2"></div>
                <div className="w-56 h-3 bg-gray-300 rounded mx-auto"></div>
              </div>
            </div>
          </WireframeBox>
        </div>

        {/* Right Side - Login Form */}
        <div className="flex-1 p-8 flex flex-col justify-center">
          <div className="max-w-sm mx-auto w-full space-y-6">
            {/* Header */}
            <div className="text-center mb-8">
              <div className="w-32 h-8 bg-gray-300 rounded mx-auto mb-2"></div>
              <div className="w-48 h-4 bg-gray-300 rounded mx-auto"></div>
            </div>

            {/* Login Form */}
            <div className="space-y-4">
              <WireframeBox height="h-12" label="Email Input">
                <div className="flex items-center w-full px-4">
                  <div className="w-5 h-5 bg-gray-300 rounded mr-3"></div>
                  <div className="text-sm text-gray-500">Email address</div>
                </div>
              </WireframeBox>

              <WireframeBox height="h-12" label="Password Input">
                <div className="flex items-center justify-between w-full px-4">
                  <div className="flex items-center">
                    <div className="w-5 h-5 bg-gray-300 rounded mr-3"></div>
                    <div className="text-sm text-gray-500">Password</div>
                  </div>
                  <div className="w-5 h-5 bg-gray-300 rounded"></div>
                </div>
              </WireframeBox>

              {/* Remember Me & Forgot Password */}
              <div className="flex items-center justify-between">
                <WireframeBox width="w-28" height="h-6" className="border-none bg-transparent">
                  <div className="flex items-center space-x-2">
                    <div className="w-4 h-4 bg-gray-300 rounded-sm"></div>
                    <div className="text-xs">Remember me</div>
                  </div>
                </WireframeBox>
                <div className="w-24 h-4 bg-gray-300 rounded"></div>
              </div>

              <WireframeBox height="h-12" label="Login Button" className="bg-gray-400 border-gray-500">
                <div className="text-sm text-white">Sign In</div>
              </WireframeBox>
            </div>

            {/* Divider */}
            <div className="flex items-center space-x-4 my-6">
              <div className="flex-1 h-px bg-gray-300"></div>
              <div className="text-sm text-gray-500">OR</div>
              <div className="flex-1 h-px bg-gray-300"></div>
            </div>

            {/* Social Login Options */}
            <div className="space-y-3">
              <WireframeBox height="h-12" label="Google Login">
                <div className="flex items-center justify-center space-x-3">
                  <div className="w-6 h-6 bg-gray-300 rounded"></div>
                  <div className="text-sm">Continue with Google</div>
                </div>
              </WireframeBox>

              <WireframeBox height="h-12" label="Microsoft Login">
                <div className="flex items-center justify-center space-x-3">
                  <div className="w-6 h-6 bg-gray-300 rounded"></div>
                  <div className="text-sm">Continue with Microsoft</div>
                </div>
              </WireframeBox>
            </div>

            {/* Sign Up Link */}
            <div className="text-center pt-6">
              <div className="text-sm text-gray-500 mb-2">Don't have an account?</div>
              <div className="w-20 h-4 bg-gray-400 rounded mx-auto"></div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}