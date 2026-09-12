/**
 * BusSense AI - Authentic Kerala Bus Sprites (SVG + CSS Animation)
 * - KSRTC Super Fast (Iconic Crimson & Yellow livery)
 * - KSRTC SWIFT (Modern Electric Orange & Silver)
 * - Kerala Private Bus (Emerald Green & Gold with aerodynamic visor)
 * Includes rotating wheel physics and scrolling LED destination ticker in Malayalam.
 */

const BUS_SPRITE_TEMPLATES = {
  KSRTC_SUPERFAST: (crowdColor, destinationText) => `
    <div class="bus-sprite-container ksrtc-sf" style="--underglow-color: ${crowdColor};">
      <div class="bus-underglow"></div>
      <svg class="bus-svg" viewBox="0 0 120 48" width="86" height="34" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <linearGradient id="ksrtcRed" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stop-color="#8B0000" />
            <stop offset="60%" stop-color="#D72638" />
            <stop offset="100%" stop-color="#A01B2C" />
          </linearGradient>
          <linearGradient id="ksrtcYellow" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stop-color="#FFD700" />
            <stop offset="100%" stop-color="#FFA500" />
          </linearGradient>
        </defs>
        <!-- Main Chassis -->
        <rect x="10" y="8" width="98" height="26" rx="4" fill="url(#ksrtcRed)" stroke="#5B0505" stroke-width="1.5" />
        <!-- Iconic Yellow Speed Stripe -->
        <polygon points="10,24 108,24 104,29 10,29" fill="url(#ksrtcYellow)" />
        <rect x="14" y="11" width="16" height="3" rx="1" fill="#FFFFFF" opacity="0.9" />
        <text x="32" y="14" font-family="'Inter', sans-serif" font-size="3.8" font-weight="900" fill="#FFFFFF" letter-spacing="0.5">KSRTC</text>
        <!-- Tinted Passenger Windows -->
        <rect x="12" y="15" width="12" height="7" rx="1.5" fill="#1C2D42" stroke="#00F0FF" stroke-width="0.5" opacity="0.85" />
        <rect x="27" y="15" width="12" height="7" rx="1.5" fill="#1C2D42" stroke="#00F0FF" stroke-width="0.5" opacity="0.85" />
        <rect x="42" y="15" width="12" height="7" rx="1.5" fill="#1C2D42" stroke="#00F0FF" stroke-width="0.5" opacity="0.85" />
        <rect x="57" y="15" width="12" height="7" rx="1.5" fill="#1C2D42" stroke="#00F0FF" stroke-width="0.5" opacity="0.85" />
        <rect x="72" y="15" width="12" height="7" rx="1.5" fill="#1C2D42" stroke="#00F0FF" stroke-width="0.5" opacity="0.85" />
        <!-- Front Curved Windshield -->
        <path d="M87,15 L98,15 Q102,15 104,20 L104,26 L87,26 Z" fill="#0B132B" stroke="#00F0FF" stroke-width="0.6" />
        <!-- Amber Headlight & Tail Light -->
        <circle cx="106" cy="30" r="2.2" fill="#FFE57F" class="bus-headlight-pulse" />
        <rect x="10" y="27" width="2" height="4" fill="#FF1744" />
        <!-- Rotating Wheel 1 (Rear) -->
        <g class="bus-wheel-rotating" transform-origin="28 34">
          <circle cx="28" cy="34" r="6" fill="#111116" stroke="#444" stroke-width="1" />
          <circle cx="28" cy="34" r="3" fill="#888" />
          <line x1="28" y1="28" x2="28" y2="40" stroke="#DDD" stroke-width="0.8" />
          <line x1="22" y1="34" x2="34" y2="34" stroke="#DDD" stroke-width="0.8" />
        </g>
        <!-- Rotating Wheel 2 (Front) -->
        <g class="bus-wheel-rotating" transform-origin="88 34">
          <circle cx="88" cy="34" r="6" fill="#111116" stroke="#444" stroke-width="1" />
          <circle cx="88" cy="34" r="3" fill="#888" />
          <line x1="88" y1="28" x2="88" y2="40" stroke="#DDD" stroke-width="0.8" />
          <line x1="82" y1="34" x2="94" y2="34" stroke="#DDD" stroke-width="0.8" />
        </g>
      </svg>
      <div class="bus-led-ticker">
        <span class="ticker-text">${destinationText}</span>
      </div>
    </div>
  `,

  KSRTC_SWIFT: (crowdColor, destinationText) => `
    <div class="bus-sprite-container ksrtc-swift" style="--underglow-color: ${crowdColor};">
      <div class="bus-underglow"></div>
      <svg class="bus-svg" viewBox="0 0 120 48" width="86" height="34" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <linearGradient id="swiftOrange" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stop-color="#FF5722" />
            <stop offset="60%" stop-color="#FF8A50" />
            <stop offset="100%" stop-color="#E64A19" />
          </linearGradient>
        </defs>
        <!-- Main Chassis -->
        <rect x="10" y="7" width="100" height="27" rx="5" fill="url(#swiftOrange)" stroke="#B23A00" stroke-width="1.5" />
        <!-- Modern Cyber Stripe -->
        <polygon points="10,23 110,23 105,27 10,27" fill="#FFFFFF" />
        <text x="34" y="13" font-family="'Inter', sans-serif" font-size="3.8" font-weight="900" fill="#FFFFFF" letter-spacing="0.8">SWIFT-EV</text>
        <!-- Modern Flush Glazing Windows -->
        <rect x="12" y="14" width="70" height="8" rx="2" fill="#0A1128" stroke="#00F0FF" stroke-width="0.5" />
        <!-- Aerodynamic Cockpit -->
        <path d="M85,14 L100,14 Q106,14 108,20 L108,26 L85,26 Z" fill="#03071E" stroke="#00F0FF" stroke-width="0.8" />
        <!-- Dual Xenon Projector Lights -->
        <circle cx="107" cy="28" r="2.2" fill="#00E5FF" class="bus-headlight-pulse" />
        <rect x="10" y="27" width="2" height="4" fill="#FF1744" />
        <!-- Rotating Wheels -->
        <g class="bus-wheel-rotating" transform-origin="28 34">
          <circle cx="28" cy="34" r="6" fill="#0B0C10" stroke="#333" stroke-width="1" />
          <circle cx="28" cy="34" r="3" fill="#00FF9D" />
          <line x1="28" y1="28" x2="28" y2="40" stroke="#FFF" stroke-width="0.8" />
          <line x1="22" y1="34" x2="34" y2="34" stroke="#FFF" stroke-width="0.8" />
        </g>
        <g class="bus-wheel-rotating" transform-origin="88 34">
          <circle cx="88" cy="34" r="6" fill="#0B0C10" stroke="#333" stroke-width="1" />
          <circle cx="88" cy="34" r="3" fill="#00FF9D" />
          <line x1="88" y1="28" x2="88" y2="40" stroke="#FFF" stroke-width="0.8" />
          <line x1="82" y1="34" x2="94" y2="34" stroke="#FFF" stroke-width="0.8" />
        </g>
      </svg>
      <div class="bus-led-ticker">
        <span class="ticker-text">${destinationText}</span>
      </div>
    </div>
  `,

  PRIVATE_BUS: (crowdColor, destinationText) => `
    <div class="bus-sprite-container pvt-bus" style="--underglow-color: ${crowdColor};">
      <div class="bus-underglow"></div>
      <svg class="bus-svg" viewBox="0 0 120 48" width="86" height="34" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <linearGradient id="pvtEmerald" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stop-color="#00796B" />
            <stop offset="50%" stop-color="#00BFA5" />
            <stop offset="100%" stop-color="#004D40" />
          </linearGradient>
          <linearGradient id="pvtGold" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stop-color="#FFD54F" />
            <stop offset="100%" stop-color="#FFA000" />
          </linearGradient>
        </defs>
        <!-- Main Body -->
        <rect x="10" y="8" width="98" height="26" rx="4" fill="url(#pvtEmerald)" stroke="#00332C" stroke-width="1.5" />
        <!-- Custom Tribal/Graphic Wave Decals -->
        <path d="M10,22 Q35,16 60,25 T108,23 L108,27 Q70,30 10,27 Z" fill="url(#pvtGold)" />
        <text x="32" y="13" font-family="'Inter', sans-serif" font-size="3.5" font-weight="900" fill="#FFD54F" letter-spacing="0.5">ROYAL RIDER</text>
        <!-- Windows with Curtain Details -->
        <rect x="12" y="15" width="13" height="6.5" rx="1.5" fill="#14213D" stroke="#FFD54F" stroke-width="0.4" />
        <rect x="28" y="15" width="13" height="6.5" rx="1.5" fill="#14213D" stroke="#FFD54F" stroke-width="0.4" />
        <rect x="44" y="15" width="13" height="6.5" rx="1.5" fill="#14213D" stroke="#FFD54F" stroke-width="0.4" />
        <rect x="60" y="15" width="13" height="6.5" rx="1.5" fill="#14213D" stroke="#FFD54F" stroke-width="0.4" />
        <rect x="76" y="15" width="13" height="6.5" rx="1.5" fill="#14213D" stroke="#FFD54F" stroke-width="0.4" />
        <!-- Visor & Front Windshield -->
        <path d="M91,15 L102,15 Q106,15 107,20 L107,26 L91,26 Z" fill="#0A0908" stroke="#00FF9D" stroke-width="0.6" />
        <!-- Triple Halogen Cluster -->
        <circle cx="106" cy="28" r="2.2" fill="#FFD700" class="bus-headlight-pulse" />
        <rect x="10" y="27" width="2" height="4" fill="#FF1744" />
        <!-- Rotating Chrome Alloy Wheels -->
        <g class="bus-wheel-rotating" transform-origin="28 34">
          <circle cx="28" cy="34" r="6" fill="#1A1A1A" stroke="#FFD54F" stroke-width="1.2" />
          <circle cx="28" cy="34" r="3" fill="#FFD54F" />
          <line x1="28" y1="28" x2="28" y2="40" stroke="#FFF" stroke-width="0.8" />
          <line x1="22" y1="34" x2="34" y2="34" stroke="#FFF" stroke-width="0.8" />
        </g>
        <g class="bus-wheel-rotating" transform-origin="88 34">
          <circle cx="88" cy="34" r="6" fill="#1A1A1A" stroke="#FFD54F" stroke-width="1.2" />
          <circle cx="88" cy="34" r="3" fill="#FFD54F" />
          <line x1="88" y1="28" x2="88" y2="40" stroke="#FFF" stroke-width="0.8" />
          <line x1="82" y1="34" x2="94" y2="34" stroke="#FFF" stroke-width="0.8" />
        </g>
      </svg>
      <div class="bus-led-ticker">
        <span class="ticker-text">${destinationText}</span>
      </div>
    </div>
  `,
};

function renderBusSprite(operatorType, crowdPercentage, destinationMalayalam) {
  let crowdColor = '#00FF9D'; // Green <50%
  if (crowdPercentage >= 85) {
    crowdColor = '#FF3B30'; // Crimson >85%
  } else if (crowdPercentage >= 50) {
    crowdColor = '#FFCC00'; // Amber 50-85%
  }

  const destText = destinationMalayalam || 'തമ്പാനൂർ ➔ ടെക്നോപാർക്ക്';

  if (operatorType === 'KSRTC_SWIFT') {
    return BUS_SPRITE_TEMPLATES.KSRTC_SWIFT(crowdColor, destText);
  } else if (operatorType === 'PRIVATE') {
    return BUS_SPRITE_TEMPLATES.PRIVATE_BUS(crowdColor, destText);
  } else {
    return BUS_SPRITE_TEMPLATES.KSRTC_SUPERFAST(crowdColor, destText);
  }
}

window.renderBusSprite = renderBusSprite;
