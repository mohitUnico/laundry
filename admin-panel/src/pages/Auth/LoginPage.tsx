import { Box, Typography } from '@mui/material'

export const LoginPage = () => {
    return (
        <Box
            sx={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                minHeight: '100vh',
            }}
        >
            <Typography variant="h3" gutterBottom>
                Laundry App - Admin Panel
            </Typography>
            <Typography variant="body1">Login page - To be implemented</Typography>
        </Box>
    )
}

