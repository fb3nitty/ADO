
'use client';

import { motion } from 'framer-motion';
import { useInView } from 'react-intersection-observer';
import { Play, FileText, Terminal, Table } from 'lucide-react';
import Image from 'next/image';

export default function ProductPreview() {
  const [ref, inView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  const previews = [
    {
      title: "PowerShell Scripts in Action",
      description: "Watch our automated scripts extract comprehensive permission data from your Azure DevOps organization",
      icon: Terminal,
      image: "https://www.thomasmaurer.ch/wp-content/uploads/2020/05/Azure-VM-Run-Command-Run-PowerShell-Script.jpg"
    },
    {
      title: "Excel Permission Matrix",
      description: "Professional Excel template with multiple worksheets for complete permission documentation and analysis",
      icon: Table,
      image: "https://i.ytimg.com/vi/VDL7jgBUZDY/maxresdefault.jpg"
    },
    {
      title: "Workflow Checklist",
      description: "Comprehensive 150+ point checklist ensuring no step is missed in your organization setup process",
      icon: FileText,
      image: "https://i.ytimg.com/vi/cMMSOve36Tg/maxresdefault.jpg"
    }
  ];

  return (
    <section id="preview" className="section-padding bg-gradient-to-br from-gray-50 to-blue-50">
      <div className="container-max">
        <motion.div
          ref={ref}
          initial={{ opacity: 0, y: 50 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8 }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-6">
            See the Toolkit in Action
          </h2>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Get a preview of what's included in our comprehensive Azure DevOps Permission Matrix Toolkit. 
            Each component is designed for professional IT environments.
          </p>
        </motion.div>

        <div className="space-y-16">
          {previews.map((preview, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 50 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.8, delay: index * 0.2 }}
              className={`grid lg:grid-cols-2 gap-12 items-center ${
                index % 2 === 1 ? 'lg:grid-flow-col-dense' : ''
              }`}
            >
              <div className={index % 2 === 1 ? 'lg:col-start-2' : ''}>
                <div className="flex items-center space-x-4 mb-6">
                  <div className="w-14 h-14 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl flex items-center justify-center">
                    <preview.icon className="h-7 w-7 text-white" />
                  </div>
                  <h3 className="text-2xl md:text-3xl font-bold text-gray-900">
                    {preview.title}
                  </h3>
                </div>

                <p className="text-lg text-gray-600 mb-8 leading-relaxed">
                  {preview.description}
                </p>

                <div className="space-y-4">
                  <div className="flex items-center space-x-3">
                    <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                    <span className="text-gray-700">Production-ready and tested</span>
                  </div>
                  <div className="flex items-center space-x-3">
                    <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                    <span className="text-gray-700">Comprehensive documentation included</span>
                  </div>
                  <div className="flex items-center space-x-3">
                    <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                    <span className="text-gray-700">Enterprise-grade security standards</span>
                  </div>
                </div>

                <button className="mt-8 inline-flex items-center space-x-2 bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors">
                  <Play className="h-5 w-5" />
                  <span>View Demo</span>
                </button>
              </div>

              <div className={index % 2 === 1 ? 'lg:col-start-1' : ''}>
                <motion.div
                  whileHover={{ scale: 1.05 }}
                  transition={{ duration: 0.3 }}
                  className="relative group"
                >
                  <div className="absolute -inset-4 bg-gradient-to-r from-blue-500 to-purple-600 rounded-2xl blur-lg opacity-20 group-hover:opacity-30 transition-opacity"></div>
                  <div className="relative bg-white rounded-2xl p-4 shadow-2xl border border-gray-200">
                    <div className="aspect-video bg-gray-100 rounded-lg overflow-hidden">
                      <Image
                        src={preview.image}
                        alt={preview.title}
                        fill
                        className="object-cover"
                      />
                    </div>
                  </div>
                </motion.div>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Feature Highlights */}
        <motion.div
          initial={{ opacity: 0, y: 50 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8, delay: 0.8 }}
          className="mt-16 bg-white rounded-2xl p-8 shadow-xl border border-gray-200"
        >
          <h3 className="text-2xl font-bold text-gray-900 mb-8 text-center">
            What Makes Our Toolkit Different
          </h3>

          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
            <div className="text-center">
              <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <span className="text-2xl font-bold text-blue-600">5</span>
              </div>
              <h4 className="font-semibold text-gray-900 mb-2">PowerShell Scripts</h4>
              <p className="text-sm text-gray-600">Automated extraction at all permission levels</p>
            </div>

            <div className="text-center">
              <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <span className="text-2xl font-bold text-green-600">150+</span>
              </div>
              <h4 className="font-semibold text-gray-900 mb-2">Checklist Items</h4>
              <p className="text-sm text-gray-600">Comprehensive workflow for setup</p>
            </div>

            <div className="text-center">
              <div className="w-16 h-16 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <span className="text-2xl font-bold text-purple-600">100%</span>
              </div>
              <h4 className="font-semibold text-gray-900 mb-2">Ready to Use</h4>
              <p className="text-sm text-gray-600">No additional configuration needed</p>
            </div>

            <div className="text-center">
              <div className="w-16 h-16 bg-orange-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <span className="text-2xl font-bold text-orange-600">24/7</span>
              </div>
              <h4 className="font-semibold text-gray-900 mb-2">Support Included</h4>
              <p className="text-sm text-gray-600">Professional support and updates</p>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
