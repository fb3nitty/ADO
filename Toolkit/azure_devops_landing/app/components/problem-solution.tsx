
'use client';

import { motion } from 'framer-motion';
import { useInView } from 'react-intersection-observer';
import { AlertTriangle, CheckCircle, Clock, Users, Shield, Zap } from 'lucide-react';
import Image from 'next/image';

export default function ProblemSolution() {
  const [ref, inView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  const problems = [
    {
      icon: AlertTriangle,
      title: "Complex Permission Structures",
      description: "Azure DevOps permissions are notoriously complex with multiple inheritance levels and overlapping scopes."
    },
    {
      icon: Clock,
      title: "Time-Consuming Manual Setup",
      description: "Setting up new organizations takes weeks of manual configuration and documentation."
    },
    {
      icon: Users,
      title: "Inconsistent Access Control",
      description: "Without proper templates, permission assignments become inconsistent across projects and teams."
    }
  ];

  const solutions = [
    {
      icon: CheckCircle,
      title: "Automated Permission Extraction",
      description: "5 PowerShell scripts automatically extract and document all permission levels across your organization."
    },
    {
      icon: Shield,
      title: "Comprehensive Documentation",
      description: "Excel templates and checklists ensure consistent, compliant permission management."
    },
    {
      icon: Zap,
      title: "Rapid Organization Setup",
      description: "150+ point workflow checklist reduces setup time from weeks to days."
    }
  ];

  return (
    <section id="problem-solution" className="section-padding bg-gray-50">
      <div className="container-max">
        <motion.div
          ref={ref}
          initial={{ opacity: 0, y: 50 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8 }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-6">
            Stop Fighting Azure DevOps Permissions
          </h2>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Every IT administrator knows the pain of Azure DevOps permission management. 
            Our toolkit transforms this complex challenge into a streamlined process.
          </p>
        </motion.div>

        <div className="grid lg:grid-cols-2 gap-16 items-center">
          {/* Problem Side */}
          <motion.div
            initial={{ opacity: 0, x: -50 }}
            animate={inView ? { opacity: 1, x: 0 } : {}}
            transition={{ duration: 0.8, delay: 0.2 }}
          >
            <div className="relative">
              <div className="absolute -top-4 -left-4 w-full h-full bg-red-100 rounded-2xl transform rotate-2"></div>
              <div className="relative bg-white rounded-2xl p-8 shadow-xl border border-red-200">
                <div className="flex items-center space-x-3 mb-6">
                  <div className="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center">
                    <AlertTriangle className="h-6 w-6 text-red-600" />
                  </div>
                  <h3 className="text-2xl font-bold text-gray-900">The Problem</h3>
                </div>

                <div className="space-y-6">
                  {problems.map((problem, index) => (
                    <motion.div
                      key={index}
                      initial={{ opacity: 0, y: 20 }}
                      animate={inView ? { opacity: 1, y: 0 } : {}}
                      transition={{ duration: 0.6, delay: 0.4 + index * 0.1 }}
                      className="flex space-x-4"
                    >
                      <div className="flex-shrink-0">
                        <problem.icon className="h-6 w-6 text-red-500 mt-1" />
                      </div>
                      <div>
                        <h4 className="font-semibold text-gray-900 mb-2">{problem.title}</h4>
                        <p className="text-gray-600">{problem.description}</p>
                      </div>
                    </motion.div>
                  ))}
                </div>

                <div className="mt-8 p-4 bg-red-50 rounded-lg border border-red-200">
                  <div className="relative aspect-video bg-gray-200 rounded-lg overflow-hidden">
                    <Image
                      src="https://learn.microsoft.com/en-us/azure/devops/organizations/security/media/permissions-page-enter-user-name.png?view=azure-devops"
                      alt="Complex Azure DevOps Permissions"
                      fill
                      className="object-cover"
                    />
                  </div>
                  <p className="text-sm text-red-700 mt-3 font-medium text-center">
                    "Another 3 hours spent trying to figure out why permissions aren't working..."
                  </p>
                </div>
              </div>
            </div>
          </motion.div>

          {/* Solution Side */}
          <motion.div
            initial={{ opacity: 0, x: 50 }}
            animate={inView ? { opacity: 1, x: 0 } : {}}
            transition={{ duration: 0.8, delay: 0.4 }}
          >
            <div className="relative">
              <div className="absolute -top-4 -right-4 w-full h-full bg-green-100 rounded-2xl transform -rotate-2"></div>
              <div className="relative bg-white rounded-2xl p-8 shadow-xl border border-green-200">
                <div className="flex items-center space-x-3 mb-6">
                  <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
                    <CheckCircle className="h-6 w-6 text-green-600" />
                  </div>
                  <h3 className="text-2xl font-bold text-gray-900">Our Solution</h3>
                </div>

                <div className="space-y-6">
                  {solutions.map((solution, index) => (
                    <motion.div
                      key={index}
                      initial={{ opacity: 0, y: 20 }}
                      animate={inView ? { opacity: 1, y: 0 } : {}}
                      transition={{ duration: 0.6, delay: 0.6 + index * 0.1 }}
                      className="flex space-x-4"
                    >
                      <div className="flex-shrink-0">
                        <solution.icon className="h-6 w-6 text-green-500 mt-1" />
                      </div>
                      <div>
                        <h4 className="font-semibold text-gray-900 mb-2">{solution.title}</h4>
                        <p className="text-gray-600">{solution.description}</p>
                      </div>
                    </motion.div>
                  ))}
                </div>

                <div className="mt-8 p-4 bg-green-50 rounded-lg border border-green-200">
                  <div className="relative aspect-video bg-gray-200 rounded-lg overflow-hidden">
                    <Image
                      src="https://i.ytimg.com/vi/DC_zqugmE9k/maxresdefault.jpg"
                      alt="Organized Permission Management"
                      fill
                      className="object-cover"
                    />
                  </div>
                  <p className="text-sm text-green-700 mt-3 font-medium text-center">
                    "Permission audit completed in 15 minutes instead of 3 days!"
                  </p>
                </div>
              </div>
            </div>
          </motion.div>
        </div>

        {/* Results Banner */}
        <motion.div
          initial={{ opacity: 0, y: 50 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8, delay: 0.8 }}
          className="mt-16 bg-gradient-to-r from-blue-600 to-purple-600 rounded-2xl p-8 text-white text-center"
        >
          <h3 className="text-2xl md:text-3xl font-bold mb-4">
            Transform Weeks of Work Into Hours
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mt-8">
            <div>
              <div className="text-4xl font-bold mb-2">95%</div>
              <div className="text-blue-100">Time Reduction</div>
            </div>
            <div>
              <div className="text-4xl font-bold mb-2">100%</div>
              <div className="text-blue-100">Compliance Ready</div>
            </div>
            <div>
              <div className="text-4xl font-bold mb-2">0</div>
              <div className="text-blue-100">Permission Gaps</div>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
