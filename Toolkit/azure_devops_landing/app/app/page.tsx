
'use client';

import { motion } from 'framer-motion';
import { useInView } from 'react-intersection-observer';
import Header from '../components/header';
import Hero from '../components/hero';
import ProblemSolution from '../components/problem-solution';
import Features from '../components/features';
import ProductPreview from '../components/product-preview';
import Benefits from '../components/benefits';
import Pricing from '../components/pricing';
import About from '../components/about';
import Footer from '../components/footer';

export default function Home() {
  return (
    <main className="min-h-screen bg-white">
      <Header />
      <Hero />
      <ProblemSolution />
      <Features />
      <ProductPreview />
      <Benefits />
      <Pricing />
      <About />
      <Footer />
    </main>
  );
}
