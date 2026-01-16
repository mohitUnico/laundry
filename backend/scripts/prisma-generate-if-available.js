/**
 * Generate Prisma Client if Prisma CLI is available in the current install.
 *
 * Why:
 * - In dev, we want `npm run dev` to work even if Prisma Client hasn't been generated yet.
 * - In production builds that omit devDependencies, Prisma CLI may be absent; we skip here
 *   and rely on the build pipeline/Dockerfile to run `prisma generate` separately.
 */

const { execSync } = require('child_process');

function hasPrismaCli() {
    try {
        require.resolve('prisma/package.json', { paths: [process.cwd()] });
        return true;
    } catch {
        return false;
    }
}

if (!hasPrismaCli()) {
    // eslint-disable-next-line no-console
    console.log('[prisma] prisma CLI not installed; skipping prisma generate');
    process.exit(0);
}

try {
    execSync('npx --no-install prisma generate', { stdio: 'inherit' });
} catch (e) {
    const msg = String(e?.message || e || '');

    // On Windows, Prisma engine DLL renames can intermittently fail with EPERM due to file locks
    // (AV scans, indexers, etc.). Dev server can still run with the already-generated client.
    if (
        process.platform === 'win32' &&
        (msg.includes('EPERM') ||
            msg.includes('operation not permitted') ||
            msg.includes('Command failed: npx --no-install prisma generate'))
    ) {
        // eslint-disable-next-line no-console
        console.warn('[prisma] prisma generate failed with EPERM; continuing without regeneration');
        process.exit(0);
    }

    throw e;
}


