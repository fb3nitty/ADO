
'use client';

import { motion } from 'framer-motion';
import { useInView } from 'react-intersection-observer';
import { 
  Clock, 
  Shield, 
  TrendingDown, 
  CheckCircle, 
  Users, 
  Zap,
  BarChart3,
  Award
} from 'lucide-react';

export default function Benefits() {
  const [ref, inView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  const benefits = [
    {
      icon: Clock,
      title: "Save 95% of Your Time",
      description: "Reduce permission audits from days to hours with automated extraction and documentation",
      metric: "95% Time Reduction",
      color: "blue"
    },
    {
      icon: Shield,
      title: "Ensure 100% Compliance",
      description: "Meet security standards and audit requirements with comprehensive permission documentation",
      metric: "100% Audit Ready",
      color: "green"
    },
    {
      icon: TrendingDown,
      title: "Eliminate Security Risks",
      description: "Identify and resolve permission gaps before they become security vulnerabilities",
      metric: "Zero Permission Gaps",
      color: "red"
    },
    {
      icon: CheckCircle,
      title: "Standardize Processes",
      description: "Implement consistent permission management across all projects and organizations",
      metric: "Consistent Standards",
      color: "purple"
    }
  ];

  const outcomes = [
    {
      icon: Users,
      title: "Team Productivity",
      before: "Weeks spent on manual permission setup",
      after: "Hours to complete comprehensive audit",
      improvement: "10x faster"
    },
    {
      icon: Shield,
      title: "Security Posture",
      before: "Unknown permission inheritance issues",
      after: "Complete visibility and documentation",
      improvement: "100% coverage"
    },
    {
      icon: BarChart3,
      title: "Compliance Reporting",
      before: "Manual compilation of permission data",
      after: "Automated reports ready for auditors",
      improvement: "Instant reports"
    },
    {
      icon: Award,
      title: "Professional Quality",
      before: "Inconsistent documentation standards",
      after: "Enterprise-grade templates and processes",
      improvement: "Professional grade"
    }
  ];

  return (
    <section id="benefits" className="section-padding bg-white">
      <div className="container-max">
        <motion.div
          ref={ref}
          initial={{ opacity: 0, y: 50 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8 }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-6">
            Transform Your Azure DevOps Management
          </h2>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Stop wasting time on manual permission management. Our toolkit delivers measurable 
            improvements to your workflow, security, and compliance posture.
          </p>
        </motion.div>

        {/* Key Benefits Grid */}
        <div className="grid md:grid-cols-2 gap-8 mb-16">
          {benefits.map((benefit, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 50 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.6, delay: index * 0.1 }}
              className={`group bg-gradient-to-br ${
                benefit.color === 'blue' ? 'from-blue-50 to-blue-100 border-blue-200' :
                benefit.color === 'green' ? 'from-green-50 to-green-100 border-green-200' :
                benefit.color === 'red' ? 'from-red-50 to-red-100 border-red-200' :
                'from-purple-50 to-purple-100 border-purple-200'
              } rounded-2xl p-8 border-2 hover:shadow-xl transition-all duration-300 transform hover:-translate-y-2`}
            >
              <div className="flex items-start space-x-6">
                <div className={`w-16 h-16 ${
                  benefit.color === 'blue' ? 'bg-blue-500' :
                  benefit.color === 'green' ? 'bg-green-500' :
                  benefit.color === 'red' ? 'bg-red-500' :
                  'bg-purple-500'
                } rounded-xl flex items-center justify-center flex-shrink-0 group-hover:scale-110 transition-transform duration-300`}>
                  <benefit.icon className="h-8 w-8 text-white" />
                </div>
                
                <div className="flex-1">
                  <h3 className="text-2xl font-bold text-gray-900 mb-3">{benefit.title}</h3>
                  <p className="text-gray-700 mb-4 leading-relaxed">{benefit.description}</p>
                  <div className={`inline-flex items-center px-4 py-2 rounded-full text-sm font-semibold ${
                    benefit.color === 'blue' ? 'bg-blue-500 text-white' :
                    benefit.color === 'green' ? 'bg-green-500 text-white' :
                    benefit.color === 'red' ? 'bg-red-500 text-white' :
                    'bg-purple-500 text-white'
                  }`}>
                    {benefit.metric}
                  </div>
                </div>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Before vs After Comparison */}
        <motion.div
          initial={{ opacity: 0, y: 50 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8, delay: 0.4 }}
          className="bg-gray-50 rounded-2xl p-8 mb-16"
        >
          <h3 className="text-3xl font-bold text-gray-900 mb-12 text-center">
            Before vs After: Real Impact
          </h3>

          <div className="grid lg:grid-cols-2 gap-8">
            {outcomes.map((outcome, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, x: index % 2 === 0 ? -50 : 50 }}
                animate={inView ? { opacity: 1, x: 0 } : {}}
                transition={{ duration: 0.6, delay: 0.6 + index * 0.1 }}
                className="bg-white rounded-xl p-6 shadow-lg border border-gray-200"
              >
                <div className="flex items-center space-x-4 mb-6">
                  <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center">
                    <outcome.icon className="h-6 w-6 text-white" />
                  </div>
                  <h4 className="text-xl font-bold text-gray-900">{outcome.title}</h4>
                </div>

                <div className="space-y-4">
                  <div className="flex items-start space-x-3">
                    <div className="w-6 h-6 bg-red-100 rounded-full flex items-center justify-center flex-shrink-0 mt-1">
                      <div className="w-2 h-2 bg-red-500 rounded-full"></div>
                    </div>
                    <div>
                      <div className="text-sm font-medium text-red-700 mb-1">Before</div>
                      <div className="text-gray-700">{outcome.before}</div>
                    </div>
                  </div>

                  <div className="flex items-start space-x-3">
                    <div className="w-6 h-6 bg-green-100 rounded-full flex items-center justify-center flex-shrink-0 mt-1">
                      <CheckCircle className="w-4 h-4 text-green-500" />
                    </div>
                    <div>
                      <div className="text-sm font-medium text-green-700 mb-1">After</div>
                      <div className="text-gray-700">{outcome.after}</div>
                    </div>
                  </div>

                  <div className="pt-4 border-t border-gray-100">
                    <div className="inline-flex items-center px-3 py-1 rounded-full bg-gradient-to-r from-green-500 to-blue-500 text-white text-sm font-semibold">
                      <Zap className="h-4 w-4 mr-1" />
                      {outcome.improvement}
                    </div>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </motion.div>

        {/* ROI Calculator */}
        <motion.div
          initial={{ opacity: 0, y: 50 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8, delay: 0.8 }}
          className="bg-gradient-to-r from-blue-600 to-purple-600 rounded-2xl p-8 text-white text-center"
        >
          <h3 className="text-3xl font-bold mb-6">Calculate Your ROI</h3>
          <p className="text-xl text-blue-100 mb-8 max-w-2xl mx-auto">
            See how much time and money you'll save with our Azure DevOps Permission Matrix Toolkit
          </p>

          <div className="grid md:grid-cols-3 gap-8 mb-8">
            <div className="bg-white/10 backdrop-blur-md rounded-xl p-6 border border-white/20">
              <div className="text-3xl font-bold mb-2">40 hours</div>
              <div className="text-blue-100">Typical manual audit time</div>
            </div>
            <div className="bg-white/10 backdrop-blur-md rounded-xl p-6 border border-white/20">
              <div className="text-3xl font-bold mb-2">2 hours</div>
              <div className="text-blue-100">With our toolkit</div>
            </div>
            <div className="bg-white/10 backdrop-blur-md rounded-xl p-6 border border-white/20">
              <div className="text-3xl font-bold mb-2">$3,800</div>
              <div className="text-blue-100">Saved per audit cycle*</div>
            </div>
          </div>

          <p className="text-sm text-blue-200">
            *Based on $100/hour IT administrator rate. Your savings may vary.
          </p>
        </motion.div>
      </div>
    </section>
  );
}
