import type { JSX } from 'react'

export function LernpfadBackground(): JSX.Element {
  return (
    <div className="absolute inset-0 overflow-hidden pointer-events-none">
      <style>{`
        @keyframes float-up {
          0% {
            transform: translateY(0);
            opacity: 0.3;
          }
          50% {
            opacity: 0.6;
          }
          100% {
            transform: translateY(-120%);
            opacity: 0;
          }
        }

        @keyframes sway {
          0%, 100% {
            transform: translateX(0);
          }
          50% {
            transform: translateX(20px);
          }
        }

        .lernpfad-cloud {
          animation: float-up linear infinite;
          position: absolute;
          opacity: 0.4;
        }

        .lernpfad-cloud:nth-child(1) {
          animation-duration: 12s;
          animation-delay: 0s;
          left: 10%;
          top: 80%;
          width: 80px;
          height: 40px;
        }

        .lernpfad-cloud:nth-child(2) {
          animation-duration: 14s;
          animation-delay: 3s;
          left: 70%;
          top: 85%;
          width: 100px;
          height: 50px;
        }

        .lernpfad-cloud:nth-child(3) {
          animation-duration: 16s;
          animation-delay: 6s;
          left: 40%;
          top: 75%;
          width: 90px;
          height: 45px;
        }

        .lernpfad-cloud:nth-child(4) {
          animation-duration: 13s;
          animation-delay: 9s;
          left: 5%;
          top: 70%;
          width: 110px;
          height: 55px;
        }
      `}</style>

      {/* Himmel Gradient */}
      <div
        className="absolute inset-0"
        style={{
          background: 'linear-gradient(to bottom, rgba(51, 77, 122, 0.05) 0%, rgba(51, 77, 122, 0.02) 50%, rgba(255, 255, 255, 0) 100%)',
        }}
      />

      {/* Wolken */}
      {[...Array(4)].map((_, i) => (
        <svg
          key={i}
          className="lernpfad-cloud"
          viewBox="0 0 100 50"
          preserveAspectRatio="none"
          aria-hidden="true"
        >
          <path
            d="M20 30 Q20 15 35 15 Q45 5 60 15 Q75 15 75 30 Z"
            fill="var(--color-primary-light)"
            opacity="0.6"
          />
          <path
            d="M25 32 Q25 20 38 20 Q48 12 62 20 Q75 20 75 32 Z"
            fill="rgba(255, 255, 255, 0.8)"
            opacity="0.5"
          />
        </svg>
      ))}

      {/* Landschaft unten */}
      <div className="absolute bottom-0 left-0 right-0 h-24 pointer-events-none">
        <svg
          viewBox="0 0 400 100"
          className="h-full w-full"
          preserveAspectRatio="xMidYMid slice"
          aria-hidden="true"
        >
          {/* Hügel 1 (dunkel) */}
          <path
            d="M0 60 Q100 20 200 50 L200 100 L0 100 Z"
            fill="var(--color-primary)"
            opacity="0.08"
          />

          {/* Hügel 2 (hell) */}
          <path
            d="M150 70 Q250 30 400 60 L400 100 L150 100 Z"
            fill="var(--color-primary)"
            opacity="0.04"
          />

          {/* Basis-Linie */}
          <line
            x1="0"
            y1="95"
            x2="400"
            y2="95"
            stroke="var(--color-border)"
            strokeWidth="1"
            opacity="0.3"
          />
        </svg>
      </div>
    </div>
  )
}
