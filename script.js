// Animate elements on scroll
const observer = new IntersectionObserver((entries) => {
    entries.forEach(e => {
        if (e.isIntersecting) {
            e.target.style.opacity = '1';
            e.target.style.transform = 'translateY(0)';
        }
    });
}, { threshold: 0.1 });

document.querySelectorAll('section').forEach(s => {
    s.style.opacity = '0';
    s.style.transform = 'translateY(20px)';
    s.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
    observer.observe(s);
});

// Make hero visible immediately
document.querySelector('.hero').style.opacity = '1';
document.querySelector('.hero').style.transform = 'translateY(0)';

// Ch2 live stats
(async function updateCh2() {
    // Days since launch (Feb 28 2026 12:00 CST = Feb 28 18:00 UTC)
    const epoch = new Date('2026-02-28T18:00:00Z');
    const days = Math.floor((Date.now() - epoch) / 86400000);
    const daysEl = document.getElementById('ch2-days');
    if (daysEl) daysEl.textContent = days + 'd';

    // Fetch live stats
    try {
        const resp = await fetch('/ch2-stats.json?' + Date.now());
        const data = await resp.json();
        const earned = document.getElementById('ch2-earned');
        const downloads = document.getElementById('ch2-downloads');
        const paid = document.getElementById('ch2-paid');
        const fill = document.getElementById('ch2-fill');

        if (earned) earned.textContent = '$' + data.earned.toLocaleString('en-US', {minimumFractionDigits: data.earned % 1 ? 2 : 0});
        if (downloads) downloads.textContent = data.downloads.toLocaleString();
        if (paid) paid.textContent = data.paid.toLocaleString();

        if (fill) {
            const pct = Math.min((data.earned / 7500) * 100, 100);
            fill.style.setProperty('--progress', pct + '%');
            fill.querySelector('.tracker-fill-label').textContent = '$' + data.earned.toLocaleString('en-US', {minimumFractionDigits: data.earned % 1 ? 2 : 0});
        }
    } catch (e) {
        console.warn('Ch2 stats fetch failed:', e);
    }
})();
