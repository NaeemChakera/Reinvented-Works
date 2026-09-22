/* ══════════════════════════════════════════════════
REINVENTED WORKS — script.js
══════════════════════════════════════════════════ */

(function () {
  'use strict';

  /* ── Theme toggle ── */
  const themeToggle = document.querySelector('[data-theme-toggle]');
  const root = document.documentElement;

  let currentTheme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  root.setAttribute('data-theme', currentTheme);
  updateThemeIcon();
  updateLogoImage();

  themeToggle && themeToggle.addEventListener('click', () => {
    currentTheme = currentTheme === 'dark' ? 'light' : 'dark';
    root.setAttribute('data-theme', currentTheme);
    themeToggle.setAttribute('aria-label', 'Switch to ' + (currentTheme === 'dark' ? 'light' : 'dark') + ' mode');
    updateThemeIcon();
    updateLogoImage();
  });

  function updateThemeIcon() {
    if (!themeToggle) return;
    themeToggle.innerHTML = currentTheme === 'dark'
      ? '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="5"/><path d="M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42"/></svg>'
      : '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>';
  }

  function updateLogoImage() {
    const logo = document.querySelector('.logo-img');
    if (!logo) return;
    const lightSrc = logo.dataset.light || logo.getAttribute('src');
    const darkSrc = logo.dataset.dark || lightSrc;
    const target = currentTheme === 'dark' ? darkSrc : lightSrc;
    if (target && logo.getAttribute('src') !== target) {
      logo.setAttribute('src', target);
    }
  }

  /* ── Sticky header scroll shadow ── */
  const header = document.getElementById('header');
  if (header) {
    let lastY = 0;
    window.addEventListener('scroll', () => {
      const y = window.scrollY;
      if (y > 8) {
        header.classList.add('header--scrolled');
      } else {
        header.classList.remove('header--scrolled');
      }
      lastY = y;
    }, { passive: true });
  }

  /* ── Mobile menu ── */
  const menuToggle = document.getElementById('menuToggle');
  const mobileNav  = document.getElementById('mobileNav');

  if (menuToggle && mobileNav) {
    menuToggle.addEventListener('click', () => {
      const isOpen = mobileNav.classList.toggle('is-open');
      menuToggle.setAttribute('aria-expanded', String(isOpen));
      mobileNav.setAttribute('aria-hidden', String(!isOpen));
    });

    // Close on nav link click
    mobileNav.querySelectorAll('a').forEach(link => {
      link.addEventListener('click', () => {
        mobileNav.classList.remove('is-open');
        menuToggle.setAttribute('aria-expanded', 'false');
        mobileNav.setAttribute('aria-hidden', 'true');
      });
    });
  }

  /* ── Scroll-reveal animations ── */
  const fadeEls = document.querySelectorAll(
    '.feature-card, .compat-card, .step, .faq-item, .gallery-item, .design-img-wrap'
  );

  fadeEls.forEach(el => el.classList.add('fade-up'));

  if ('IntersectionObserver' in window) {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry, i) => {
        if (entry.isIntersecting) {
          // Stagger siblings within the same parent
          const siblings = [...entry.target.parentElement.children].filter(c => c.classList.contains('fade-up'));
          const idx = siblings.indexOf(entry.target);
          setTimeout(() => {
            entry.target.classList.add('visible');
          }, idx * 60);
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });

    fadeEls.forEach(el => observer.observe(el));
  } else {
    // Fallback: show immediately
    fadeEls.forEach(el => el.classList.add('visible'));
  }

  /* ── Smooth active nav highlight on scroll ── */
  const sections = document.querySelectorAll('section[id]');
  const navLinks = document.querySelectorAll('.nav-link');

  if (sections.length && navLinks.length) {
    const sectionObserver = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          navLinks.forEach(link => {
            link.style.color = '';
            link.style.fontWeight = '';
          });
          const active = document.querySelector(`.nav-link[href="#${entry.target.id}"]`);
          if (active) {
            active.style.color = 'var(--color-accent)';
            active.style.fontWeight = '600';
          }
        }
      });
    }, { threshold: 0.35 });

    sections.forEach(s => sectionObserver.observe(s));
  }

  /* ── Feature carousel ── */
  const carousel = document.querySelector('[data-carousel]');
  if (carousel) {
    const track = carousel.querySelector('.design-carousel__track');
    const slides = Array.from(carousel.querySelectorAll('.design-carousel__slide'));
    const dots = Array.from(carousel.querySelectorAll('.design-carousel__dot'));
    const prevButton = carousel.querySelector('[data-carousel-prev]');
    const nextButton = carousel.querySelector('[data-carousel-next]');

    let activeIndex = 0;
    let startX = 0;
    let deltaX = 0;

    function updateDots(index) {
      activeIndex = (index + slides.length) % slides.length;
      dots.forEach((dot, dotIndex) => {
        dot.classList.toggle('is-active', dotIndex === activeIndex);
      });
    }

    function scrollToSlide(index) {
      activeIndex = (index + slides.length) % slides.length;
      slides[activeIndex].scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'start' });
      updateDots(activeIndex);
    }

    function showNextSlide() {
      scrollToSlide(activeIndex + 1);
    }

    function showPrevSlide() {
      scrollToSlide(activeIndex - 1);
    }

    prevButton && prevButton.addEventListener('click', () => {
      showPrevSlide();
    });

    nextButton && nextButton.addEventListener('click', () => {
      showNextSlide();
    });

    dots.forEach((dot) => {
      dot.addEventListener('click', () => {
        scrollToSlide(Number(dot.dataset.carouselDot));
      });
    });

    carousel.addEventListener('touchstart', (event) => {
      startX = event.touches[0].clientX;
      deltaX = 0;
    }, { passive: true });

    carousel.addEventListener('touchmove', (event) => {
      deltaX = event.touches[0].clientX - startX;
    }, { passive: true });

    carousel.addEventListener('touchend', () => {
      if (deltaX < -50) {
        showNextSlide();
      } else if (deltaX > 50) {
        showPrevSlide();
      }
    });

    track.addEventListener('scroll', () => {
      const slideWidth = slides[0]?.getBoundingClientRect().width || 0;
      if (!slideWidth) return;
      const nearestIndex = Math.round(track.scrollLeft / slideWidth);
      updateDots(Math.min(Math.max(nearestIndex, 0), slides.length - 1));
    }, { passive: true });

    track.scrollLeft = 0;
    updateDots(0);
  }

  /* ── FAQ: close others when one opens ── */
  const faqItems = document.querySelectorAll('.faq-item');
  faqItems.forEach(item => {
    item.addEventListener('toggle', () => {
      if (item.open) {
        faqItems.forEach(other => {
          if (other !== item && other.open) other.open = false;
        });
      }
    });
  });

})();
