import React, { useState, useEffect } from 'react';
import { Outlet } from 'react-router-dom';
import { Sidebar } from './Sidebar';
import { Header } from './Header';

export const MainLayout: React.FC = () => {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const toggleSidebar = () => setSidebarOpen(!sidebarOpen);

  // Close sidebar when clicking outside on mobile
  useEffect(() => {
    const handleResize = () => {
      if (window.innerWidth >= 1024) {
        setSidebarOpen(false);
      }
    };

    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  return (
    <div className="h-screen overflow-hidden bg-[#F7F7F7] p-3 sm:p-4 md:p-5 lg:p-6">
      <div className="mx-auto h-full w-full max-w-[1440px]">
        <div className="relative flex h-full min-h-0 gap-4 sm:gap-5 md:gap-6">
          {/* Sidebar */}
          <Sidebar isOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />

          {/* Overlay for mobile */}
          {sidebarOpen && (
            <div
              className="fixed inset-0 bg-black/40 z-40 lg:hidden transition-opacity duration-300"
              onClick={() => setSidebarOpen(false)}
              aria-hidden="true"
            />
          )}

          {/* Main Content */}
          <div className="flex-1 min-w-0 overflow-hidden">
            <div className="h-full min-h-0 flex flex-col gap-4 sm:gap-5 md:gap-6">
              <Header onMenuClick={toggleSidebar} />
              <main className="flex-1 min-h-0 overflow-y-auto">
                <Outlet />
              </main>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

