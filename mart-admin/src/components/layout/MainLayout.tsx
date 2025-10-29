import { Outlet } from 'react-router-dom'
import { Box } from '@mui/material'

export const MainLayout = () => {
    return (
        <Box sx={{ display: 'flex', minHeight: '100vh' }}>
            {/* TODO: Add Sidebar component */}
            <Box component="main" sx={{ flexGrow: 1, p: 3 }}>
                {/* TODO: Add Header component */}
                <Outlet />
            </Box>
        </Box>
    )
}

